# Battery sublet file
# Created with sur-0.1
configure :battery do |s| # {{{
  s.interval = 60
  s.full     = 0
  s.color    = ""

  # Path
  s.now      = ""
  s.status   = ""

  # Icons
  s.icons = {
    :ac      => Subtlext::Icon.new("ac.xbm"),
    :full    => Subtlext::Icon.new("bat_full_02.xbm"),
    :low     => Subtlext::Icon.new("bat_low_02.xbm"),
    :empty   => Subtlext::Icon.new("bat_empty_02.xbm"),
    :unknown => Subtlext::Icon.new("ac.xbm")
  }

  # Options
  s.color_text = true  == s.config[:color_text]
  s.color_icon = false == s.config[:color_icon] ? false : true
  s.color_def  = Subtlext::Subtle.colors[:sublets_fg]

  # Collect colors
  if(s.config[:colors].is_a?(Hash))
    s.colors = {}

    s.config[:colors].each do |k, v|
      s.colors[k] = Subtlext::Color.new(v)
    end

    # Just sort once
    s.color_keys = s.colors.keys.sort.reverse
  end

  # Find battery slot and capacity
  begin
    path = s.config[:path] || Dir["/sys/class/power_supply/B*"].first
    now  = ""
    full = ""

    if(File.exist?(File.join(path, "charge_full")))
      full = "charge_full"
      now  = "charge_now"
    elsif(File.exist?(File.join(path, "energy_full")))
      full = "energy_full"
      now  = "energy_now"
    end

    # Assemble paths
    s.now    = File.join(path, now)
    s.status = File.join(path, "status")

    # Get full capacity
    s.full = IO.readlines(File.join(path, full)).first.to_i
  rescue => err
    puts err, err.backtrace
    raise "Could't find any battery"
  end
end # }}}

on :run do |s| # {{{
  begin
    now     = IO.readlines(s.now).first.to_i
    state   = IO.readlines(s.status).first.chop
    percent = (now * 100 / s.full).to_i

    # Select color
    unless(s.colors.nil?)
      # Find start color from top
      s.color_keys.each do |k|
        break if(k < percent)
        s.color = s.colors[k] if(k >= percent)
      end
    end

    # Select icon for state
    icon = case state
      when "Charging"  then :ac
      when "Discharging"
        case percent
          when 67..100 then :full
          when 34..66  then :low
          when 0..33   then :empty
        end
      when "Full"      then :ac
      else                  :unknown
    end

    s.data = "%s%s%s%d%%" % [
      s.color_icon ? s.color : s.color_def, s.icons[icon],
      s.color_text ? s.color : s.color_def, percent
    ]
  rescue => err # Sanitize to prevent unloading
    s.data = "subtle"
    p err
  end
end # }}}
