# Volume sublet file
# Created with sur-0.2.143

# Mixer class {{{
class Mixer
  # Copied from linux/soundcard.h
  VOLUME = 0 # Line 743
  PCM    = 4 # Line 747

  # Copied from asm-generic/ioctl.h
  IOC_WRITE = 1 # line 58
  IOC_READ  = 2 # line 62

  # Values for Linux
  IOC_NRBITS   = 8  # Line 22
  IOC_TYPEBITS = 8  # Line 23
  IOC_SIZEBITS = 14 # Line 31
  IOC_NRSHIFT  = 0  # Line 43

  IOC_TYPESHIFT = (IOC_NRSHIFT + IOC_NRBITS)     # Line 44
  IOC_SIZESHIFT = (IOC_TYPESHIFT + IOC_TYPEBITS) # Line 45
  IOC_DIRSHIFT  = (IOC_SIZESHIFT + IOC_SIZEBITS) # Line 46

  # Volume icon
  attr_reader :icon

  # Mixer state
  attr_reader :state

  ## initialize {{{
  # Initializer
  # @param [Fixnum]  channel  Mixer channel
  # @param [String]  dev      Mixer device
  ##

  def initialize(channel = Mixer::VOLUME, dev = "/dev/mixer")
    @icon    = Subtlext::Icon.new(4, 10)
    @mixer   = File.open(dev, "r")
    @channel = channel
    @state   = :on
    @volume  = [ 0, 0 ]
    @restore = 0

    get_volume

    ObjectSpace.define_finalizer(self, self.class.finalize)
  end # }}}

  ## get_volume {{{
  # Get volume
  # @return [Array] Left and right channel
  ##

  def get_volume
    vol = [ 0, 0 ].pack("cc")

    @mixer.ioctl(mixer_read(@channel), vol)

    @volume = vol.unpack("cc")

    update

    @volume
  end # }}}

  ## set_volume {{{
  # Set volume
  # @param [Fixnum]  vol  New volume
  ##

  def set_volume(vol)
    return unless 0 <= vol and 100 >= vol

    @volume = [ vol, vol ]

    volume = @volume.pack("cc")

    update

    @mixer.ioctl(mixer_write(@channel), volume)
  end # }}}

  ## louder {{{
  # Increase volume
  # @param [Fixnum]  step  Increase step
  ##

  def louder(step = 5)
    vol = get_volume.first # Left channel

    set_volume(vol + step)
  end # }}}

  ## quieter {{{
  # Decrease volume
  # @param [Fixnum]  step  Decrease step
  ##

  def quieter(step = 5)
    vol = get_volume.first # Left channel

    set_volume(vol - step)
  end # }}}

  ## toggle {{{
  # Toggle mute
  ###

  def toggle
    if :off == @state
      @state = :on

      set_volume(@restore)
    else
      @state = :off

      @restore = @volume.first
      set_volume(0)
    end

    update
  end # }}}

  ## update {{{
  # Update state and icon
  ###

  def update
    # Set state
    @state = case @volume.first
      when 0 then :off
      else :on
    end

    # Draw meter
    height = (@volume.first * @icon.height / 100)
    @icon.clear
    @icon.draw_rect(0, @icon.height - height, @icon.width, height, true)
  end # }}}

  ## finalize {{{
  # Close mixer
  ###

  def self.finalize
    proc { @mixer.close unless @mixer.nil? }
  end # }}}

  private

  ## ioc {{{
  # Assemble ioctl number
  # @param [Fixnum]  dir   Directive
  # @param [Fixnum]  type  Command type
  # @param [Fixnum]  nr    Command number
  # @param [Fixnum]  size  Value size
  # @return [Fixnum] Ioctl number
  ##

  def ioc(dir, type, nr, size = 4) # 4 => sizeof(int)
    # Defined in asm-generic/ioctl.h on line 65
    ((dir << IOC_DIRSHIFT) | (type << IOC_TYPESHIFT) | (nr << IOC_NRSHIFT) | (size << IOC_SIZESHIFT))
  end # }}}

  ## mixer_read {{{
  # Get mixer read ioctl
  # @param [Fixnum]  dev  Mixer device
  # @return [Fixnum] Ioctl number
  ##

  def mixer_read(dev)
    # Defined in linux/soundcard.h on line 846
    [ioc(IOC_READ, "M".ord, dev)].pack("i").unpack("i").first
  end # }}}

  ## mixer_write {{{
  # Get mixer write ioctl
  # @param [Fixnum]  dev  Mixer device
  # @return [Fixnum] Ioctl number
  ##

  def mixer_write(dev)
    # Defined in linux/soundcard.h on line 876
    [ioc(IOC_READ|IOC_WRITE, "M".ord, dev)].pack("i").unpack("i").first
  end # }}}
end # }}}

configure :volume do |s| # {{{
  s.interval = 240
  s.step     = s.config[:step] || 5
  s.mixer    = Mixer.new
  s.icons    = {
    :on  => Subtlext::Icon.new("spkr_01.xbm"),
    :off => Subtlext::Icon.new("spkr_02.xbm")
  }
end # }}}

# Hooks
on :mouse_down do |s, x, y, b| # {{{
  case b
    when 1 then s.mixer.toggle
    when 4 then s.mixer.louder(s.step)
    when 5 then s.mixer.quieter(s.step)
  end

  s.data = "%s%s" % [ s.icons[s.mixer.state], s.mixer.icon ]
end # }}}

on :run do |s| # {{{
  s.mixer.get_volume

  s.data = "%s%s" % [ s.icons[s.mixer.state], s.mixer.icon ]
end # }}}

# Grabs
grab :VolumeRaise do |s| # {{{
  s.mixer.louder(s.step)

  s.data = "%s%s" % [ s.icons[s.mixer.state], s.mixer.icon ]
end # }}}

grab :VolumeLower do |s| # {{{
  s.mixer.quieter(s.step)

  s.data = "%s%s" % [ s.icons[s.mixer.state], s.mixer.icon ]
end # }}}

grab :VolumeToggle do |s| # {{{
  s.mixer.toggle

  s.data = "%s%s" % [ s.icons[s.mixer.state], s.mixer.icon ]
end # }}}
