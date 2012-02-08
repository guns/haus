import XMonad
import XMonad.Layout.MouseResizableTile

main = do
    xmonad $ defaultConfig
        { modMask           = controlMask .|. mod4Mask
        , terminal          = "rxvt-unicode --client"
        , borderWidth       = 0
        , focusFollowsMouse = False
        , layoutHook        = mouseResizableTile { masterFrac = 0.7, fracIncrement = 0.05, draggerType = BordersDragger }
        }
