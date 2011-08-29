# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

configure :time do |s|
  s.interval = s.config[:interval] || 60
  s.format   = s.config[:format]   || '%a %-d %b %-I:%M%P'
end

on :run do |s|
  s.data = Time.now.strftime s.format
end
