# Volume specification file
# Created with sur-0.2.143
Sur::Specification.new do |s|
  # Sublet information
  s.name        = "Volume"
  s.version     = "0.4"
  s.tags        = [ "Icon", "Ioctl", "Linux", "Config", "Grab" ]
  s.files       = [ "volume.rb" ]
  s.icons       = [
    "icons/spkr_01.xbm",
    "icons/spkr_02.xbm"
  ]

  # Sublet authors
  s.authors     = [ "unexist" ]
  s.contact     = "unexist@dorfelite.net"
  s.date        = "Mon Mar 14 15:16 CEST 2011"

  # Sublet description
  s.description = "Display and control the volume"
  s.notes       = <<NOTES
This sublet shows the volume of the default mixer device, this works
with ALSA and OSS sound systems.

Left click toggles mute, mouse wheel up and down changes the volume.
NOTES

  # Sublet config
  s.config = [
    {
      :name        => "step",
      :type        => "integer",
      :description => "Volume increase/decrease steps",
      :def_value   => "5"
    }
  ]

  # Sublet grabs
  s.grabs = {
    :VolumeRaise  => "Increase volume",
    :VolumeLower  => "Decrease volume",
    :VolumeToggle => "Toggle mute"
  }

  # Sublet requirements
  s.required_version = "0.9.2620"
end
