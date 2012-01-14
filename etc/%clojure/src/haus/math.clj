(ns haus.math)

(defn leading-digit [n]
  "Return the high order digit (base10) of a number; e.g. for Benford's law."
  (let [div (int (Math/pow 10 (int (Math/log10 (int n)))))]
    (int (/ n div))))

(defn pascals-triangle []
  "Return a lazy seq of rows of Pascal's triangle."
  (letfn [(next-row [row]
            (reduce (fn [v' v] (conj v' (apply +' (take 2 v)))) ; (take 2) returns [1] at the right edge
                    [1]                                         ; Left edge
                    (take (count row) (iterate rest row))))]
    (iterate next-row [1])))

(defn counts-by [& args]
  "Like group-by, but values are replaced by their counts."
  (into {} (for [[k v] (apply group-by args)] [k (count v)])))
