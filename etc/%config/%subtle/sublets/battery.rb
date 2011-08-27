# Battery sublet file
# Created with sur-0.1
configure :battery do |s|
  s.interval = 60
  s.full     = 0

  # Path
  s.now      = ""
  s.status   = ""

  # Icons
  s.iconify = lambda { |f| Subtlext::Icon.new File.expand_path("../icons/#{f}", __FILE__) }
  s.icons = {
    :ac      => s.iconify.call("ac.xbm"),
    :full    => s.iconify.call("bat_full_02.xbm"),
    :low     => s.iconify.call("bat_low_02.xbm"),
    :empty   => s.iconify.call("bat_empty_02.xbm"),
    :unknown => s.iconify.call("ac.xbm")
  }

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
end

on :run do |s|
  begin
    now     = IO.readlines(s.now).first.to_i
    state   = IO.readlines(s.status).first.chop
    percent = (now * 100 / s.full).to_i

    # Select icon
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

    s.data = "%s%d%%" % [ s.icons[icon], percent ]
  rescue => err # Sanitize to prevent unloading
    s.data = "subtle"
    p err
  end
end
