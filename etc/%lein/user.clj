(ns user)

;;
;; Swap javadoc URLs to local versions
;;

(require 'clojure.java.javadoc)

(let [core-url clojure.java.javadoc/*core-java-api*
      local-url "http://api.dev/jdk7/api/"]
  (dosync
    (alter clojure.java.javadoc/*remote-javadocs*
           #(reduce (fn [m [pre url]]
                      (assoc m pre (if (= url core-url)
                                     local-url
                                     url)))
                    {} %)))
  (alter-var-root #'clojure.java.javadoc/*core-java-api*
                  (constantly local-url)))

;;
;; Debugging
;;

(require 'clojure.pprint
         'clojure.tools.trace
         'spyscope.core
         'redl.core
         'redl.complete
         'no.disassemble)

(defmacro p [& xs]
  `(do (clojure.pprint/pprint
         (zipmap '~(reverse xs) [~@(reverse xs)]))
       ~(last xs)))

(defmacro dump-locals []
  `(clojure.pprint/pprint
     ~(into {} (map (fn [l] [`'~l l]) (reverse (keys &env))))))

(defmacro trace
  ([expr] `(trace *ns* ~expr))
  ([nspace expr]
   `(try (clojure.tools.trace/trace-ns ~nspace)
         ~expr
         (finally (clojure.tools.trace/untrace-ns ~nspace)))))

(defn disassemble [obj]
  (println (no.disassemble/disassemble obj)))

;;
;; Warnings
;;

(def warnings (atom {}))

(defn print-warnings-atom []
  (clojure.pprint/pprint @warnings))

(defn toggle-warn-on-reflection!
  ([]
   (toggle-warn-on-reflection! (not *warn-on-reflection*))
   (print-warnings-atom))
  ([value]
   (set! *warn-on-reflection* value)
   (swap! warnings assoc '*warn-on-reflection* value)))

(try
  (require 'schema.core)
  (catch Throwable _))

(defmacro toggle-schema-validation!
  ([]
   `(do (toggle-schema-validation! (not (@warnings :validate-schema?)))
        (print-warnings-atom)))
  ([value]
   (when (find-ns 'schema.core)
     `(do (schema.core/set-fn-validation! ~value)
          (swap! warnings assoc :validate-schema? ~value)))))

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

(require 'clojure.tools.namespace.repl)

(def refresh clojure.tools.namespace.repl/refresh)

(try
  (require 'system)
  (load-file (str (System/getProperty "user.home") "/.lein/user/system.clj"))
  (catch Throwable _))

;;
;; Reflection
;;

(require 'clojure.reflect)

(def reflect clojure.reflect/reflect)

(defn cheat-sheet [nspace]
  (let [n (str nspace)
        vars (vals (ns-publics nspace))
        fn-var? #(let [f (deref %)]
                   (or (contains? (meta %) :arglists)
                       (fn? f)
                       (instance? clojure.lang.MultiFn f)))
        {funs true
         defs false} (group-by fn-var? vars)
        fmeta (map meta funs)
        dmeta (map meta defs)
        flen (apply max 0 (map (comp count str :name) fmeta))
        dnames (map #(str n \/ (:name %)) dmeta)
        fnames (map #(format (str "%s/%-" flen "s %s") n (:name %)
                             (clojure.string/join \space (:arglists %)))
                    fmeta)
        lines (concat (sort dnames) (sort fnames))]
    (str ";;; " n " {{{1\n\n"
         (clojure.string/join \newline lines))))

(defn write-cheat-sheet! [pattern]
  (let [matches (->> (all-ns)
                     (filter #(re-seq pattern (str %)))
                     (sort-by str))]
    (if (seq matches)
      (let [tmp (java.io.File.
                  (format "target/vim/cheat-sheet-%s.clj"
                          (clojure.string/replace pattern #"[\x00/\n]" \.)))
            buf (str (clojure.string/join "\n\n" (map cheat-sheet matches))
                     "\n\n;; vim:ft=clojure:fdm=marker:")]
        (clojure.java.io/make-parents tmp)
        (spit tmp buf)
        (.getAbsolutePath tmp))
      "")))

(defn classpath []
  (doseq [u (seq (.getURLs ^java.net.URLClassLoader (ClassLoader/getSystemClassLoader)))]
    (println (.getPath ^java.net.URL u))))

(defn type-scaffold
  "https://gist.github.com/mpenet/2053633, originally by cgrand"
  [^Class cls]
  (let [ms (map (fn [^java.lang.reflect.Method m]
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
                              "\n  " (clojure.string/join "\n  " decls))))
                     (group-by first ms))]
    idecls))

(defn object-scaffold [obj]
  (let [cls (if (class? obj) obj (class obj))
        decls (->> cls supers (mapcat type-scaffold) distinct sort)]
    (clojure.string/join "\n\n" decls)))

;;
;; Testing
;;

(defn run-tests-for-current-ns []
  (let [p (re-pattern (str "\\Q" *ns* "\\E-test\\z"))
        n (if (re-seq #"-test\z" (str *ns*))
            *ns*
            (first (filter #(re-seq p (str %)) (all-ns))))]
    (require (ns-name *ns*) (ns-name n) :reload)
    (clojure.test/run-tests n)))

;;
;; Benchmarking
;;

(require 'criterium.core)

(defmacro bm [expr]
  `(do (printf "%s\n\n" '~expr)
       (criterium.core/quick-bench ~expr)
       (newline)))

(defmacro bench [expr]
  `(do (printf "%s\n\n" '~expr)
       (criterium.core/bench ~expr)
       (newline)))
