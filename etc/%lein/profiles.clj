
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
                  [lein-gorilla "RELEASE"]
                  [lein-kibit "RELEASE"]
                  [lein-nodisassemble "RELEASE"]]
        :dependencies [[com.taoensso/timbre "RELEASE"]
                       [criterium "RELEASE"]
                       [org.clojure/tools.namespace "RELEASE"]
                       [org.clojure/tools.trace "RELEASE"]
                       [redl "RELEASE"]
                       [slamhound "LATEST"]
                       [spyscope "RELEASE"]]
        :aliases {"t" ["trampoline"]
                  "RUN" ["trampoline" "run"]
                  "REPL" ["trampoline" "repl" ":headless"]
                  "slamhound" ["trampoline" "run" "-m" "slam.hound"]}
        :signing {:gpg-key "0x4BC72AA6B1AE2B5AC7F7ADCF9D1AA266D2BC9C2D"}
        :global-vars {*warn-on-reflection* true}
        :repl-options
        {:init-ns user
         :init (do (load-file (str (System/getProperty "user.home") "/.lein/user.clj"))
                   (user/toggle-warnings! true))}}}
