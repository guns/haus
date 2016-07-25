(ns guns.system
  "Stuart Sierra's Clojure Workflow, Reloaded
   http://thinkrelevance.com/blog/2013/06/04/clojure-workflow-reloaded
   https://github.com/stuartsierra/component#reloading"
  (:require [clojure.tools.namespace.repl :as ctnr]
            [com.stuartsierra.component :as component]))

;; Once so we don't lose a reference to an instance on reload
(defonce ^{:doc "Stores active application instance."}
  instance
  (atom nil))

(defn system-status
  "Active instance status. May be one of #{nil :init :start :stop}"
  []
  (:status (meta @instance)))

(defn init
  "Create a new application instance."
  []
  (when (nil? @instance)
    (reset! instance (vary-meta (eval `(system/system)) assoc :status :init))))

(defn start
  "Start the current application instance."
  []
  (when (contains? #{:init :stop} (system-status))
    (swap! instance #(vary-meta (component/start %) assoc :status :start))))

(defn stop
  "Shut down the active application instance."
  []
  (when (= :start (system-status))
    (swap! instance #(vary-meta (component/stop %) assoc :status :stop))))

(defn destroy
  "Destroy the active application instance."
  []
  (when-not (= :start (system-status))
    (reset! instance nil)
    true))

(defn boot []
  (and (destroy)
       (init)
       (start)))

(defn restart []
  (stop)
  (destroy)
  (ctnr/refresh :after `boot))
