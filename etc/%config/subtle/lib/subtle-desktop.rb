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
        c.tags = [Subtlext::Tag.find(name) || names.first].flatten
      end
    end
  end

  # Emulate OS X's app-document model by binding keys to focus a class of
  # applications or create a new instance.
  def open keys, command, args
    grab keys do
      extant = Subtlext::Client.all.find do |c|
        c.send(args.first).send *args.drop(1)
      end

      if extant
        extant.focus
        extant.raise
      else
        spawn *[command].flatten
      end
    end
  end
end
