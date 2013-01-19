(ns test.core
  (:require [foobarbaz.core :as foo :refer [bar baz quux]]))

;;; Foo "bar" baz function
(defn example
  [foos bars bazs]
  (map (fn
         (iterate (x (y (z)))))
       foos bars bazs))
