(ns user.system
  "Stuart Sierra's Clojure Workflow, Reloaded
   http://thinkrelevance.com/blog/2013/06/04/clojure-workflow-reloaded"
  (:require [clojure.tools.namespace.repl :refer [refresh]]))

;; Once so we don't lose a reference to an instance on reload
(defonce ^{:doc "Stores active application instance."}
  instance
  (atom nil))

;; XXX: Why does reloading only work with (eval)?!
(defn init
  "Create a new application instance."
  []
  (eval
    `(when-not @instance
       (reset! instance (system/system)))))

(defn start
  "Start the current application instance."
  []
  (eval
    `(when @instance
       (swap! instance (partial system/start)))))

(defn stop
  "Shut down and destroy the active application instance."
  []
  (eval
    `(when @instance
       (system/stop @instance)
       (reset! instance nil)
       instance)))

(defn boot []
  (and (init) (start)))

(defn restart []
  (stop)
  (refresh :after `boot))
