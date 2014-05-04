(ns guns.repl
  (:require [clojure.core :as cc]
            [clojure.java.io :as io]
            [clojure.java.javadoc :as javadoc]
            [clojure.pprint :as pp]
            [clojure.reflect :as reflect]
            [clojure.string :as string]
            [clojure.test :as test]
            [clojure.tools.namespace.repl :as ctnr]
            [clojure.tools.trace :as trace]
            [criterium.core :as crit]
            [no.disassemble :as no]
            [slam.hound.regrow :as regrow])
  (:import (clojure.lang MultiFn)
           (java.io File PrintWriter)
           (java.lang.management ManagementFactory)
           (java.lang.reflect Method)
           (java.net URL URLClassLoader))
  (:refer-clojure :exclude [time]))

;;
;; Global State
;;

(defn set-local-javadocs!
  "Swap javadoc URLs to local versions."
  []
  (let [core-url javadoc/*core-java-api*
        local-url "http://api.dev/jdk7/api/"]
    (dosync
      (alter javadoc/*remote-javadocs*
             #(reduce (fn [m [pre url]]
                        (assoc m pre (if (= url core-url)
                                       local-url
                                       url)))
                      {} %)))
    (alter-var-root #'javadoc/*core-java-api* (constantly local-url))))

(defn set-local-pprint-values! []
  (alter-var-root #'pp/*print-miser-width* (constantly nil))
  (alter-var-root #'pp/*print-right-margin* (constantly 80)))

;;
;; Debugging
;;

(defmacro with-err [& body]
  `(binding [*out* (new ~PrintWriter System/err true)]
     ~@body))

(defmacro p [& xs]
  `(do (~pp/pprint (zipmap '~(reverse xs) [~@(reverse xs)]))
       ~(last xs)))

(defmacro perr [& xs]
  `(do (.println System/err (zipmap '~(reverse xs) [~@(reverse xs)]))
       ~(last xs)))

(defmacro dump-locals []
  `(~pp/pprint
     ~(into {} (map (fn [l] [`'~l l]) (reverse (keys &env))))))

(defmacro trace
  {:require [#'trace/trace-ns]}
  ([expr]
   `(trace *ns* ~expr))
  ([ns expr]
   `(try (trace/trace-ns ~ns)
         ~expr
         (finally (trace/untrace-ns ~ns)))))

(defn disassemble [obj]
  (println (no/disassemble obj)))

(defn debug-slamhound! []
  (alter-var-root #'regrow/*debug* not))

(defmacro print-errors [& body]
  `(try
     ~@body
     (catch ~Throwable e#
       (.println System/err e#)
       (throw e#))))

;;
;; Warnings
;;

(def warnings (atom {}))

(defn print-warnings-atom []
  (prn @warnings))

(defn toggle-warn-on-reflection!
  ([]
   (toggle-warn-on-reflection! (not *warn-on-reflection*))
   (print-warnings-atom))
  ([value]
   (set! *warn-on-reflection* value)
   (swap! warnings assoc '*warn-on-reflection* value)))

(defn toggle-schema-validation! [& _])

;; Runtime handling of prismatic/schema
(try
  (require 'schema.core)

  (defn toggle-schema-validation!
    ([]
     (toggle-schema-validation! (not (@warnings :validate-schema?)))
     (print-warnings-atom))
    ([value]
     (eval `(schema.core/set-fn-validation! ~value))
     (swap! warnings assoc :validate-schema? value)))
  (catch Throwable _))

(defn toggle-warnings!
  ([]
   (toggle-warnings! (not *warn-on-reflection*)))
  ([value]
   (toggle-warn-on-reflection! value)
   (toggle-schema-validation! value)
   (print-warnings-atom)))

;;
;; Reloading
;;

(def refresh ctnr/refresh)
(def refresh-all ctnr/refresh-all)

;;
;; Reflection
;;

(def reflect reflect/reflect)

(defn fn-var? [v]
  (let [f @v]
    (or (contains? (meta v) :arglists)
        (fn? f)
        (instance? MultiFn f))))

(defn cheat-sheet [ns]
  (let [nsname (str ns)
        vars (vals (ns-publics ns))
        {funs true
         defs false} (group-by fn-var? vars)
        fmeta (map meta funs)
        dmeta (map meta defs)
        flen (apply max 0 (map (comp count str :name) fmeta))
        dnames (map #(str nsname \/ (:name %)) dmeta)
        fnames (map #(format (str "%s/%-" flen "s %s") nsname (:name %)
                             (string/join \space (:arglists %)))
                    fmeta)
        lines (concat (sort dnames) (sort fnames))]
    (str ";;; " nsname " {{{1\n\n"
         (string/join \newline lines))))

(defn write-cheat-sheet! [pattern]
  (let [matches (->> (all-ns)
                     (filter #(re-find pattern (str %)))
                     (sort-by str))]
    (if (seq matches)
      (let [tmp (File. (format "target/cheat-sheets/%s.clj"
                               (string/replace pattern #"[^\w-]" ".")))
            buf (str (string/join "\n\n" (map cheat-sheet matches))
                     "\n\n;; vim:ft=clojure:fdm=marker:")]
        (io/make-parents tmp)
        (spit tmp buf)
        (.getAbsolutePath tmp))
      "")))

(defn classpath []
  (let [classloader (ClassLoader/getSystemClassLoader)]
    (mapv (fn [^URL u] (.getPath u)) (.getURLs ^URLClassLoader classloader))))

(defn print-classpath! []
  (doseq [path (classpath)]
    (println path)))

(defn jvm-args []
  (.getInputArguments (ManagementFactory/getRuntimeMXBean)))

(defn print-jvm-args! []
  (doseq [arg (jvm-args)]
    (println arg)))

(defn type-scaffold
  "https://gist.github.com/mpenet/2053633, originally by cgrand"
  [^Class cls]
  (let [ms (map (fn [^Method m]
                  [(.getDeclaringClass m)
                   (symbol (.getName m))
                   (map #(symbol (.getCanonicalName ^Class %)) (.getParameterTypes m))])
                (.getMethods cls))
        idecls (mapv (fn [[^Class cls ms]]
                       (let [decls (map (fn [[_ s ps]] (str (list s (into ['this] ps))))
                                        ms)
                             typ (if (.isInterface cls) "Interface" "Superclass")]
                         (str "  ;; " typ
                              "\n  " (.getCanonicalName cls)
                              "\n  " (string/join "\n  " decls))))
                     (group-by first ms))]
    idecls))

(defn object-scaffold [obj]
  (let [cls (if (class? obj) obj (class obj))
        decls (->> cls supers (mapcat type-scaffold) distinct sort)]
    (string/join "\n\n" decls)))

;;
;; Testing
;;

(defn run-tests-for-current-ns
  ([]
   (run-tests-for-current-ns nil))
  ([var-pat]
   (let [ns-pat (re-pattern (str "\\Q" *ns* "\\E-test\\z"))
         ns (if (re-find #"-test\z" (str *ns*))
              *ns*
              (first (filter #(re-find ns-pat (str %)) (all-ns))))]
     (require (ns-name *ns*) (ns-name ns) :reload)
     (if var-pat
       (let [v (->> (ns-publics ns)
                    vals
                    (filter (fn [v] (re-find var-pat (str (:name (meta v)))))))]
         (printf "Running %d test%s\n" (count v) (if (= (count v) 1) "" \s))
         (test/test-vars v))
       (test/run-tests ns)))))

;;
;; Benchmarking
;;

(defmacro time
  {:requires [#'with-err #'cc/time]}
  [& body]
  `(with-err (cc/time ~@body)))

(defmacro bm
  {:require [#'crit/quick-bench]}
  [expr]
  `(do (printf "%s\n\n" '~expr)
       (crit/quick-bench ~expr)
       (newline)))

(defmacro bench
  {:require [#'crit/bench]}
  [expr]
  `(do (printf "%s\n\n" '~expr)
       (crit/bench ~expr)
       (newline)))

;;
;; Initialization
;;

(defn init! []
  (println "Setting javadoc URLs… ")
  (set-local-javadocs!)

  (println "Setting clojure.pprint values… ")
  (set-local-pprint-values!)

  (println "Enabling warnings… ")
  (toggle-warnings! true)

  (println "Enabling redl and spyscope… ")
  (require 'spyscope.core 'spyscope.repl 'redl.core 'redl.complete)

  (printf "Loading guns.system… ")
  (try
    (require 'system)
    (load-file (str (System/getProperty "user.home")
                    "/.local/lib/clojure/guns/src/guns/system.clj"))
    (println "OK")
    (catch Throwable _
      (println "N/A"))))
