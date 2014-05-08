(ns guns.lint
  "Contains a rudimentary linter for resource leaks.

   If an AutoCloseable object is created, but not closed in a finally block
   immediately following the binding vector in which it is opened, a warning
   is issued.

   e.g.

     ;; `from` and `to` are never closed!
     (let [from (PushbackReader. (io/reader input))
           to (io/output-stream output)]
       (io/copy from to))

     ;; (closeable-warnings *ns*)
     ;; -> ({:ns … :line … :form [from (new PushbackReader (io/reader input))]}
     ;;     {:ns … :line … :form [to (io/output-stream output]})

     (with-open [from (PushbackReader. (io/reader input))
                 to (io/output-stream output)]
       (io/copy from to))
   "
  (:require [clojure.java.io :as io]
            [clojure.tools.analyzer :as ana]
            [clojure.tools.analyzer.ast :as ast]
            [clojure.tools.analyzer.jvm :as jvm])
  (:import (clojure.lang LineNumberingPushbackReader Namespace)
           (java.io ByteArrayInputStream ByteArrayOutputStream StringReader
                    StringWriter)
           (java.lang AutoCloseable)))

(def NOP-CLOSEABLES
  "Set of classes whose close methods are NOPs. Includes StringReader, whose
   close method does have an effect. However, as the source is a String,
   hardly anybody bothers closing it."
  #{ByteArrayInputStream
    ByteArrayOutputStream
    StringReader
    StringWriter})

(defn ^:private analyze [form]
  (binding [ana/macroexpand-1 jvm/macroexpand-1
            ana/create-var    jvm/create-var
            ana/parse         jvm/parse
            ana/var?          var?]
    (jvm/analyze form (jvm/empty-env))))

(defn ^:private closeable-opening-form? [ast]
  (let [{:keys [op tag]} ast]
    (and (contains? #{:new :invoke} op)
         (class? tag)
         (not (contains? NOP-CLOSEABLES tag))
         (.isAssignableFrom AutoCloseable tag))))

(defn ^:private close-call? [ast]
  (and (= :instance-call (:op ast))
       (= 'close (:method ast))))

(defn ^:private instance-sym [ast]
  (-> ast :instance :form))

(defn ^:private closed-in-scope?
  "Only detects resource management in a let or loop, followed by a
   try/finally, with .close called in the finally clause. This is the
   macroexpansion of clojure.core/with-open, as well as good practice.

   e.g. (loop-or-let [rsrc (ctor)]
          (try
            body
            (finally
              (.close rsrc))))
   "
  [scope-ast resource-ast]
  (let [{:keys [form]} resource-ast
        [stmts ret] ((juxt :statements :ret) (-> scope-ast :body :ret :finally))]
    (->> (conj stmts ret)
         (filterv close-call?)
         (mapv instance-sym)
         (some #{form})
         boolean)))

(defn ^:private add-unclosed-nodes [unclosed node]
  (->> (:bindings node)
       (filterv #(and (closeable-opening-form? (:init %))
                      (not (closed-in-scope? node %))))
       (into unclosed)))

(defn ^:private find-unclosed-resources [form]
  (loop [unclosed #{} [node & more] (ast/nodes (analyze form))]
    (if node
      (if (closeable-opening-form? node)
        ;; A Closeable form outside of a binding vector is considered unclosed
        (recur (conj unclosed node) more)
        (if (contains? #{:let :loop} (:op node))
          ;; Process this binding form, then skip ahead to the body
          (recur (add-unclosed-nodes unclosed node)
                 (drop-while #(not= :do (:op %)) more))
          (recur unclosed more)))
      unclosed)))

(defn closeable-warnings [^Namespace ns]
  (with-open [rdr (->> (str ns)
                       (replace {\. \/ \- \_})
                       (apply str)
                       (format "%s.clj")
                       io/resource
                       io/reader
                       LineNumberingPushbackReader.)]
    (let [form (binding [*ns* ns
                         *read-eval* false]
                 (doall
                   (take-while (partial not= ::done)
                               (repeatedly #(read rdr false ::done)))))
          errors (find-unclosed-resources form)]
      (doall
        (for [ast errors
              :let [{:keys [ns line]} (:env ast)
                    bind (:form ast)
                    value (-> ast :init :form)]]
          (array-map
            :ns ns
            :line line
            :form (if value [bind value] bind)))))))
