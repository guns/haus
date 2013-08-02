
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

{:user {:plugins [[lein-exec "0.3.0"]
                  [lein-kibit "0.0.8"]
                  [lein-ancient "0.4.4"]]
        :dependencies [[org.clojure/tools.trace "0.7.5"]
                       [slamhound "1.4.0"]]
        :aliases {"RUN" ["trampoline" "run"]
                  "REPL" ["trampoline" "repl" ":headless"]}
        :repl-options {:init (do (require 'clojure.java.javadoc)
                                 (let [core-url clojure.java.javadoc/*core-java-api*
                                       local-url "http://api/jdk7/api/"]
                                   (dosync
                                     (alter clojure.java.javadoc/*remote-javadocs*
                                            #(reduce
                                               (fn [m [pre url]]
                                                 (assoc m pre (if (= url core-url)
                                                                local-url
                                                                url)))
                                               {} %)))
                                   (alter-var-root
                                     #'clojure.java.javadoc/*core-java-api*
                                     (constantly local-url))))}}}
