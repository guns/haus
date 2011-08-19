#
# == Options
#
# Following options change behaviour and sizes of the window manager:
#

# Window move/resize steps in pixel per keypress
set :step, 5

# Window screen border snapping
set :snap, 10

# Default starting gravity for windows. Comment out to use gravity of
# currently active client
set :gravity, :center66

# Make transient windows urgent
set :urgent, true

# Honor resize size hints globally
set :resize, false

# Enable gravity tiling
set :tiling, false

# Font string either take from e.g. xfontsel or use xft
set :font, 'xft:Menlo:pixelsize=12'

# Separator between sublets
set :separator, '|'

# Set the WM_NAME of subtle (Java quirk)
# set :wmname, "LG3D"
