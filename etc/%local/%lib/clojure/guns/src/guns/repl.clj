(ns guns.repl
  (:require [clojure.core :as cc]
            [clojure.java.io :as io]
            [clojure.java.javadoc :as javadoc]
            [clojure.pprint :as pp]
            [clojure.reflect :as reflect]
            [clojure.set :as set]
            [clojure.string :as string]
            [clojure.test :as test]
            [clojure.tools.namespace.file :as ctnf]
            [clojure.tools.namespace.find :as find]
            [clojure.tools.namespace.repl :as ctnr]
            [clojure.tools.trace :as trace]
            [criterium.core :as crit]
            [loom.graph :as graph]
            [loom.io :as loom]
            [no.disassemble :as no]
            [slam.hound.regrow :as regrow])
  (:import (clojure.lang Cons ExceptionInfo Keyword LazySeq MultiFn Symbol)
           (java.io File PrintWriter)
           (java.lang.management ManagementFactory)
           (java.lang.reflect Method)
           (java.net URL URLClassLoader URLDecoder)
           (java.util.regex Pattern))
  (:refer-clojure :exclude [time]))

;;
;; Global State
;;

(defn set-local-javadocs!
  "Swap javadoc URLs to local versions."
  [local-url]
  (let [core-url javadoc/*core-java-api*]
    (dosync
      (alter javadoc/*remote-javadocs*
             #(reduce (fn [m [pre url]]
                        (assoc m pre (if (= url core-url)
                                       local-url
                                       url)))
                      {} %)))
    (alter-var-root #'javadoc/*feeling-lucky* (constantly false))
    (alter-var-root #'javadoc/*core-java-api* (constantly local-url))))

(defn set-print-length!
  ([length]
   (set-print-length! length length))
  ([length level]
   (alter-var-root #'*print-length* (constantly length))
   (alter-var-root #'*print-level* (constantly level))
   (set! *print-length* length)
   (set! *print-level* level)
   nil))

(defn set-local-pprint-values! [cols]
  (alter-var-root #'pp/*print-miser-width* (constantly nil))
  (alter-var-root #'pp/*print-right-margin* (constantly cols)))

;;
;; Transformation
;;

(defn- list-like? [form]
  (or (list? form)
      (instance? Cons form)
      (instance? LazySeq form)))

(defn- wrap-list [form]
  (if (list-like? form)
    form
    (list form)))

(defn thread-form [op ^String clj-string]
  (let [thread (fn thread [form]
                 (if (list? form)
                   (if (> (count form) 1)
                     (let [[head & tail] form
                           [x more] (case op
                                      -> [(first tail) (next tail)]
                                      ->> [(last tail) (butlast tail)])]
                       (concat (wrap-list (thread x))
                               [(if more (cons head more) head)]))
                     (list form))
                   form))
        form (thread
               (binding [*read-eval* false]
                 (read-string clj-string)))
        sep (if (.contains clj-string "\n")
              \newline
              \space)]
    (str "(" op " " (string/join sep (mapv pr-str form)) ")")))

(defn unthread-form [^String clj-string]
  (let [unthread (fn unthread [[form & more] op]
                   (if more
                     (let [[head & tail] more
                           form' (if (list-like? head)
                                   (case op
                                     -> (concat [(first head) ::sep form ::sep] (rest head))
                                     ->> (concat head [::sep form]))
                                   (list head ::sep form))]
                       (unthread (cons form' tail) op))
                     form))
        [op & form] (binding [*read-eval* false]
                      (read-string clj-string))
        sep (if (.contains clj-string "\n")
              "\n"
              " ")]
    (if (contains? '#{-> ->>} op)
      (-> (unthread form op)
          pr-str
          (string/replace #"\s*\Q:guns.repl/sep\E\s*" sep))
      clj-string)))

;;
;; Classpath and Namespaces
;;

(defn classpath []
  (for [^URL url (.getURLs ^URLClassLoader (ClassLoader/getSystemClassLoader))]
    (URLDecoder/decode (.getPath url) "UTF-8")))

(defn ns-deps
  ([]
   (ns-deps (classpath)))
  ([paths]
   (->> paths
        (map io/file)
        (filter #(.isDirectory ^File %))
        (mapcat find/find-clojure-sources-in-dir)
        (ctnf/add-files {})
        ((fn [{deps :clojure.tools.namespace.track/deps
               pjns :clojure.tools.namespace.track/load}]
           {:proj-namespaces (set pjns)
            :dependencies (:dependencies deps)
            :dependents (:dependents deps)})))))

(defn subtree
  ([tree node]
   (subtree tree node {}))
  ([tree node m]
   (let [nodes (get tree node)]
     (if (seq nodes)
       (reduce (fn [m n] (subtree tree n m))
               (assoc m node nodes) nodes)
       m))))

(defn view-ns-graph*
  "Visualize project namespace dependencies. Constraints are:

   Boolean:   Scope selector, project namespaces only if false
   Keyword:   Graph type, one of :dependents or :dependencies
   Symbol:    Root ns nodes
   Pattern:   Root ns nodes, filtered by pattern
   String:    Source directories to search for namespaces"
  [& constraints]
  (let [{scopes Boolean
         graph-types Keyword
         dirs String
         root-nodes Symbol
         patterns Pattern} (group-by class constraints)
        all-namespaces? (or (last scopes) false)
        graph-type (or (last graph-types) :dependents)
        dirs (or dirs (classpath))
        {:keys [proj-namespaces] graph graph-type} (ns-deps dirs)
        root-nodes (if patterns
                     (reduce
                       (fn [s pat]
                         (into s (filterv #(re-find pat (str %)) proj-namespaces)))
                       (or root-nodes #{}) patterns)
                     root-nodes)
        graph (if all-namespaces?
                graph
                (-> graph
                    (select-keys proj-namespaces)
                    (#(zipmap (keys %)
                              (mapv (partial set/intersection proj-namespaces)
                                    (vals %))))))
        graph (if (or (seq root-nodes) (seq patterns))
                (->> root-nodes
                     (mapv (partial subtree graph))
                     (apply merge-with set/union))
                graph)]
    (when (seq graph)
      (loom/view (if (= graph-type :dependencies)
                   (graph/transpose (graph/digraph graph))
                   (graph/digraph graph))))))

(defmacro view-ns-graph
  "Convenience macro for view-ns-graph*, meant for quick use from an editor.
   Bare symbols are converted to Patterns."
  [& constraints]
  `(view-ns-graph* ~@(for [c constraints]
                       (if (symbol? c)
                         (Pattern/compile (str c))
                         c))))

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

(def ^:dynamic *dump-file* "target/dump.clj")

(defn truncate-dump-file! []
  (spit *dump-file* ""))

(defmacro dump! [& body]
  `(spit *dump-file*
         (with-out-str (~pp/pprint (do ~@body)))
         :append true))

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
   (alter-var-root #'*warn-on-reflection* (constantly value))
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
      (let [tmp (io/file (format "target/cheat-sheets/%s.clj"
                                 (string/replace pattern #"[^\w-]" ".")))
            buf (str (string/join "\n\n" (map cheat-sheet matches))
                     "\n\n;; vim:ft=clojure:fdm=marker:")]
        (io/make-parents tmp)
        (spit tmp buf)
        (.getAbsolutePath tmp))
      "")))

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
        idecls (map (fn [[^Class cls ms]]
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

(defn test-vars
  "Copied from clojure.test/test-vars for backwards compat.

   Groups vars by their namespace and runs test-vars on them with
   appropriate fixtures applied."
  {:added "1.6"}
  [vars]
  (doseq [[ns vars] (group-by (comp :ns meta) vars)]
    (let [once-fixture-fn (test/join-fixtures (:clojure.test/once-fixtures (meta ns)))
          each-fixture-fn (test/join-fixtures (:clojure.test/each-fixtures (meta ns)))]
      (once-fixture-fn
       (fn []
         (doseq [v vars]
           (when (:test (meta v))
             (each-fixture-fn (fn [] (test/test-var v))))))))))

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
         (test-vars v))
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
  (set-local-javadocs! "http://api.dev/jdk7/api/")

  (println "Setting *print-length* and *print-level*… ")
  (set-print-length! 1024 64)

  (println "Setting clojure.pprint values… ")
  (set-local-pprint-values! 80)

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
