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
  (let [xs (filter #(re-seq re (str %))
                   (nspace/find-namespaces-on-classpath))
        xs' (reduce (fn [v x]
                      (if (try (require x) true (catch Exception _))
                        (conj v x)
                        v))
                    [] xs)]
    (println (apply cheat-sheet (sort-by strvar xs')))))

(defn print-clojure-cheat-sheet! []
  (print-cheat-sheet! #"\Aclojure\.(?!tools\.namespace)"))
