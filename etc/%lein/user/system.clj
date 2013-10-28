(ns user.system
  "Stuart Sierra's Clojure Workflow, Reloaded
   http://thinkrelevance.com/blog/2013/06/04/clojure-workflow-reloaded"
  (:require [clojure.tools.namespace.repl :refer [refresh]]))

(def instance
  "Stores active application instance."
  nil)

(defn init
  "Create a new application instance."
  []
  (when-not instance
    (alter-var-root #'instance (constantly (system/system)))))

(defn start
  "Start the current application instance."
  []
  (when-not (:started (meta #'instance))
    (alter-var-root #'instance (constantly (system/start instance)))
    (alter-meta! #'instance assoc :started true)))

(defn stop
  "Shut down and destroy the active application instance."
  []
  (when instance
    (system/stop instance))
  (alter-meta! #'instance dissoc :started)
  (alter-var-root #'instance (constantly nil)))

(defn boot []
  (when-not instance
    (init)
    (start)))

(defn restart []
  (when instance (stop))
  (refresh :after 'user.system/boot))
