(ns haus.math)

(defn leading-digit
  "Return the high order digit (base10) of a number; e.g. for Benford's law."
  [n]
  (let [div (int (Math/pow 10 (int (Math/log10 (int n)))))]
    (int (/ n div))))

(defn counts-by
  "Like group-by, but values are replaced by their counts."
  [& args]
  (into {} (for [[k v] (apply group-by args)] [k (count v)])))

(defn pascals-triangle
  "Return a lazy seq of rows of Pascal's triangle."
  []
  (letfn [(next-row [row]
            (reduce (fn [v' v] (conj v' (apply +' (take 2 v)))) ; (take 2) returns [1] at the right edge
                    [1]                                         ; Left edge
                    (take (count row) (iterate rest row))))]
    (iterate next-row [1])))

(defn rand-seq
  "Return a lazy seq of (rand ceil) invocations"
  ([]
   (lazy-seq (cons (rand) (rand-seq))))
  ([ceil]
   (lazy-seq (cons (rand ceil) (rand-seq ceil)))))

(defn primes
  "Lazy seq of primes.
  Commented version of Christophe Grande's beautiful solution.
  http://clj-me.cgrand.net/2009/07/30/everybody-loves-the-sieve-of-eratosthenes/"
  []
  (letfn [(assoc-mult [sieve m p]
            ;; We want the next *odd* prime multiple
            (let [m' (+ m (* 2 p))]
              (if (sieve m')
                ;; We have seen this multiple before, so keep going
                (recur sieve m' p)
                ;; Return the sieve with this new multiple key
                (assoc sieve m' p))))
          (next-sieve [sieve n]
            ;; The sieve is a map of highest-known-multiples -> prime-factors
            (if-let [p (sieve n)]
              ;; Thus if the sieve sifts n, we update the sieve for prime p
              (assoc-mult (dissoc sieve n) n p)
              ;; Otherwise, n has never been seen before and is thus prime
              (assoc-mult sieve n n)))
          (next-prime [sieve n]
            (let [sieve' (next-sieve sieve n) n' (+ n 2)]
              (if (sieve n)
                ;; This n is a prime multiple; consider the next number
                (recur sieve' n')
                ;; This n is prime; return n with the next computation
                (cons n (lazy-seq (next-prime sieve' n'))))))]
    ;; Seed the first prime, then cons on the lazy computation
    (cons 2 (lazy-seq (next-prime {} 3)))))
