#
# == Styles
#
# Styles define various properties of styleable items in a CSS-like syntax.
#
# If no background color is given no color will be set. This will ensure a
# custom background pixmap won't be overwritten.
#
# === Link
#
# http://subforge.org/projects/subtle/wiki/Styles

# Style for focus window title
style :title do
  padding     0, 3
  border      "#303030", 0
  foreground  "#fecf35"
  background  "#202020"
end

# Style for the active views
style :focus do
  padding     0, 3
  border      "#303030", 0
  foreground  "#fecf35"
  background  "#202020"
end

# Style for urgent window titles and views
style :urgent do
  padding     0, 3
  border      "#303030", 0
  foreground  "#ff9800"
  background  "#202020"
end

# Style for occupied views (views with clients)
style :occupied do
  padding     0, 3
  border      "#303030", 0
  foreground  "#b8b8b8"
  background  "#202020"
end

# Style for view buttons
style :unoccupied do
  padding     0, 3
  border      "#303030", 0
  foreground  "#757575"
  background  "#202020"
end

# Style for sublets
style :sublets do
  padding     0, 5
  border_left "#303030", 0
  foreground  "#757575"
  background  "#202020"
end

# Style for separator
style :separator do
  padding     0, 3
  border      0
  background  "#202020"
  foreground  "#757575"
end

# Style for active/inactive windows
style :clients do
  active      "#303030", 2
  inactive    "#202020", 2
  margin      0
  width       50
end

# Style for subtle
style :subtle do
  margin      0, 0, 0, 0
  panel       "#202020"
  stipple     "#757575"
  # background  "#3d3d3d" # Don't overwrite wallpaper
end
