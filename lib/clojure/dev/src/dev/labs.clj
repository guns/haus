(ns dev.labs)

(defmacro defn+
  "clojure.core/defn with more destructuring sugar."
  [& forms]
  (let [[l r] (split-with (comp not vector?) forms)
        [lb rb] (split-with #(not= '& %) (first r))
        rb' (map (fn [e]
                   (cond
                     ;; (defn+ λ [& {a 1 b 2}])
                     (and (map? e) (every? symbol? (keys e)))
                     {:keys (keys e) :or e}
                     ;; (defn+ λ [& {:keys {a 1 b 2}}])
                     (and (contains? e :keys) (map? (:keys e)))
                     (assoc e :keys (keys (:keys e)) :or (:keys e))
                     ;; Pass through
                     :else e))
                 rb)]
    `(defn ~@(concat l (cons (vec (concat lb rb')) (rest r))))))
