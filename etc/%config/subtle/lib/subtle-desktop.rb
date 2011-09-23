# -*- encoding: utf-8 -*-

module SubtleDesktop
  # Emulate a more traditional multiple desktop setup:
  #
  #   - One (eponymous) tag per view
  #   - W-index to switch to view
  #   - W-S-index to move (retag) client to view
  #
  def create_desktops names
    names.each_with_index do |name, i|
      tag  name
      view name, name

      grab "W-#{i+1}", "ViewJump#{name}".to_sym

      grab "W-S-#{i+1}" do |c|
        c.toggle_stick if c.is_stick?
        c.tags = [Subtlext::Tag.find(name) || names.first]
      end
    end
  end

  # Check your config before reloading Subtle!
  def config_valid?
    system 'subtle --check'
  end

  # Emulate OS X's app-document model
  def open keys, command, args
    grab keys do
      extant = Subtlext::Client.all.find do |c|
        c.send(args.first).send *args.drop(1)
      end

      if extant
        extant.focus
        extant.raise
      else
        system *[command].flatten
      end
    end
  end

  # Arbitrarily set client properties; an alternative to the tagging system
  def set_properties c
    case c.klass

    when /u?rxvt|xterm/i
      c.toggle_borderless
      c.gravity = (c.name =~ /tmux/i ? :center : :center50)

    when /chrom(e|ium)|firefox|namoroka/i
      c.gravity = :center75

    when /vlc/i
      c.toggle_borderless
      c.gravity = :center75

    when /wireshark/i
      c.gravity = :center

    end
  end
end
