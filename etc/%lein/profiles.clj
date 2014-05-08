
;; ###
;;  ###             #                 #
;;   ##            ###               ###
;;   ##             #                 #
;;   ##
;;   ##      /##  ###   ###  /###   ###   ###  /###     /###      /##  ###  /###
;;   ##     / ###  ###   ###/ #### / ###   ###/ #### / /  ###  / / ###  ###/ #### /
;;   ##    /   ###  ##    ##   ###/   ##    ##   ###/ /    ###/ /   ###  ##   ###/
;;   ##   ##    ### ##    ##    ##    ##    ##    ## ##     ## ##    ### ##    ##
;;   ##   ########  ##    ##    ##    ##    ##    ## ##     ## ########  ##    ##
;;   ##   #######   ##    ##    ##    ##    ##    ## ##     ## #######   ##    ##
;;   ##   ##        ##    ##    ##    ##    ##    ## ##     ## ##        ##    ##
;;   ##   ####    / ##    ##    ##    ##    ##    ## ##     ## ####    / ##    ##
;;   ### / ######/  ### / ###   ###   ### / ###   ### ########  ######/  ###   ###
;;    ##/   #####    ##/   ###   ###   ##/   ###   ###  ### ###  #####    ###   ###
;;                                                           ###
;;                                                     ####   ###
;;        guns <self@sungpae.com>                    /######  /#
;;                                                  /     ###/

{:user {:plugins [[jonase/eastwood "RELEASE"]
                  [lein-ancient "RELEASE"]
                  [lein-exec "RELEASE"]
                  [lein-kibit "RELEASE"]
                  [lein-nevam "RELEASE"]
                  [lein-nodisassemble "RELEASE"]
                  [lein-vanity "RELEASE"]]
        :dependencies [[criterium "RELEASE"]
                       [aysylu/loom "0.4.3-SNAPSHOT"]
                       [org.clojure/tools.analyzer "0.1.0-beta12"]
                       [org.clojure/tools.analyzer.jvm "0.1.0-beta12"]
                       [org.clojure/tools.namespace "RELEASE"]
                       [org.clojure/tools.trace "RELEASE"]
                       [redl "RELEASE"]
                       [slamhound "[,)"]
                       [spyscope "RELEASE"]
                       #_[tailrecursion/boot.core "RELEASE"]]
        :aliases {"t" ["trampoline"]
                  "RUN" ["trampoline" "run"]
                  "REPL" ["trampoline" "repl" ":headless"]
                  "slamhound" ["trampoline" "with-profile" "user,dev,slamhound" "run" "-m" "slam.hound"]}
        :signing {:gpg-key "0x4BC72AA6B1AE2B5AC7F7ADCF9D1AA266D2BC9C2D"}
        :global-vars {*warn-on-reflection* true
                      *print-length* 500
                      *print-level* 500}
        :jvm-opts ["-XX:+CMSClassUnloadingEnabled"]
        :repl-options {:init-ns user
                       :init (do (load-file (str (System/getProperty "user.home")
                                                 "/.local/lib/clojure/guns/src/guns/repl.clj"))
                                 (guns.repl/init!))}
        :eastwood {:all true}}
 :slamhound {:global-vars {*warn-on-reflection* false}
             :injections [(require 'clojure.pprint)
                          (alter-var-root #'clojure.pprint/*print-right-margin* (constantly 78))]}}
