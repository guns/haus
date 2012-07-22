import XMonad

main = do
    xmonad $ defaultConfig
        { modMask           = controlMask .|. mod4Mask
        , terminal          = "rxvt-unicode --client"
        , borderWidth       = 0
        , focusFollowsMouse = False
        }
