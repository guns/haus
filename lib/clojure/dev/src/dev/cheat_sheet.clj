(ns dev.cheat-sheet
  (:require [clojure.string :as str]
            [clojure.tools.namespace :as nspace]))

(defn strvar [v]
  (str/replace-first (str v) #"\A#'" ""))

(defn cheat-sheet [& namespaces]
  (str/join
    "\n\n"
    (map (fn [nsp]
           (str ";;; " (strvar nsp) " {{{1\n\n"
                (str/join "\n" (sort (map strvar (vals (ns-publics nsp)))))))
         namespaces)))

(defn print-cheat-sheet! [re]
  (let [ns (sort-by strvar (filter #(re-seq re (str %))
                                   (nspace/find-namespaces-on-classpath)))]
    (doseq [n ns]
      (try (require n) (catch Exception _)))
    (println (apply cheat-sheet ns))))

(defn print-clojure-cheat-sheet! []
  (print-cheat-sheet! #"\Aclojure\.(?!tools\.namespace)"))
