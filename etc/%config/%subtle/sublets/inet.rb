# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

configure :inet do |s|
  s.interval = s.config[:interval] || 60
  s.iconify = lambda { |f| Subtlext::Icon.new File.expand_path("../icons/#{f}", __FILE__) }
  s.icons = {
    :down => s.iconify.call('down.xbm'),
    :wifi => s.iconify.call('wifi.xbm'),
    :wire => s.iconify.call('wire.xbm')
  }
end

on :run do |s|
  route = File.read('/proc/net/route').lines.drop(1).map(&:split).find do |l|
    # /usr/include/linux/route.h
    # Flags & RTF_GATEWAY
    (l[3].to_i(16) & 0x0002) != 0
  end

  s.data = '%s%s' % if route.nil?
    [s.icons[:down], 'lo']
  elsif route.first =~ /\Awlan/
    [s.icons[:wifi], route.first]
  else
    [s.icons[:wire], route.first]
  end
end
