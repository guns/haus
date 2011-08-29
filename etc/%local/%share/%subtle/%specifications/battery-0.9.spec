# Battery specification file
# Created with sur-0.1
Sur::Specification.new do |s|
  # Sublet information
  s.name        = "Battery"
  s.version     = "0.9"
  s.tags        = [ "Sys", "Icon", "Config" ]
  s.files       = [ "battery.rb" ]
  s.icons       = [
    "icons/ac.xbm",
    "icons/bat_full_02.xbm",
    "icons/bat_low_02.xbm",
    "icons/bat_empty_02.xbm"
  ]

  # Sublet description
  s.description = "Show the battery state"
  s.notes       = <<NOTES
This sublet displays the remaining battery power (percent) and the
state of the power adapter. (icon)

A hash with colors for different percentages can be passed to the
sublet, hash index is the desired percentage and the value the
color.

Example:

sublet :battery do
  colors 10 => "#ff0000", 30 => "#fff000"
end
NOTES

  # Sublet authors
  s.authors     = [ "Christoph Kappel" ]
  s.date        = "Fri Apr 21 14:23 CET 2011"
  s.contact     = "chkappel@gmail.com"

  # Sublet config
  s.config      = [
    {
      :name        => "path",
      :type        => "string",
      :description => "Path of the battery",
      :def_value   => "/sys/class/power_supply/B*"
    },
    {
      :name        => "colors",
      :type        => "hash",
      :description => "Hash with color values for percent",
      :def_value   => "{}"
    },
    {
      :name        => "color_icon",
      :type        => "bool",
      :description => "Use colors for the icon",
      :def_value   => "true"
    },
    {
      :name        => "color_text",
      :type        => "bool",
      :description => "Use colors for the text",
      :def_value   => "false"
    }
  ]
end
