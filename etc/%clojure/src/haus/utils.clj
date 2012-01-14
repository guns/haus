(ns haus.utils)

(defn leading-digit [n]
  "Return the high order digit (base10) of a number; e.g. for Benford's law."
  (let [div (int (Math/pow 10 (int (Math/log10 (int n)))))]
    (int (/ n div))))

(defn pascals-triangle []
  "Return a lazy seq of rows of Pascal's triangle."
  (letfn [(next-row [row]
            (reduce (fn [v' v] (conj v' (apply + (take 2 v)))) ; (take 2) returns [1] at the right edge
                    [1]                                        ; Left edge
                    (take (count row) (iterate rest row))))]   ; 'count is a performance liability
    (iterate next-row [1])))
