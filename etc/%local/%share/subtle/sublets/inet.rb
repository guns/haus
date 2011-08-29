# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

configure :inet do |s|
  s.interval = s.config[:interval] || 60
  s.icons = {
    :down => Subtlext::Icon.new('down.xbm'),
    :wifi => Subtlext::Icon.new('wifi.xbm'),
    :wire => Subtlext::Icon.new('wire.xbm')
  }
end

on :run do |s|
  # Find the gateway interface
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
