# Battery specification file
# Created with sur-0.1
Sur::Specification.new do |s|
  # Sublet information
  s.name        = "Battery"
  s.version     = "0.8"
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
NOTES

  # Sublet authors
  s.authors     = [ "unexist" ]
  s.date        = "Fri Apr 21 14:23 CET 2011"
  s.contact     = "unexist@dorfelite.net"

  # Sublet config
  s.config      = [
    { :name => "path", :type => "string", :description => "Path of the battery" }
  ]
end
