# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011-2017 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

require 'digest/sha1'

module NERV; end
module NERV::Util; end

module NERV::Util::Password
  extend self

  PASSWORD_LENGTH = 60
  ASCII = (0x21..0x7e).map &:chr # Printable non-whitespace characters
  ALPHA = ASCII.grep /[a-zA-Z0-9]/
  DIGIT = ASCII.grep /[0-9]/

  # Stream an IO object to a block, `bitlen` bits at a time.
  #
  # Note that this is effectively an implementation of `rand(ceil)`, where
  # `ceil` is a power of 2 and the entropy source is an arbitrary file.
  #
  # Example:
  #
  #   count = 0
  #   File.open '/dev/random', 'r' do |f|
  #     stream f, 12 do |n|
  #       puts '%4d: %012b' % [n, n]
  #       break if (count += 1) > 3
  #     end
  #   end
  #
  # outputs:
  #
  #    301: 000100101101
  #   3446: 110101110110
  #   1847: 011100110111
  #   1921: 011110000001
  #
  def stream io, bitlen = 8
    buf = len = 0
    loop do
      until len >= bitlen
        byte = io.getbyte
        raise EOFError if byte.nil?
        len += 8
        buf <<= 8
        buf |= byte
        # puts "byte:  %08b\nbuf:   %0#{len}b (%d/%d)\n" % [byte, buf, len, bitlen]
      end
      len -= bitlen
      # puts "FLUSH: %0#{bitlen}b" % (buf >> len)
      yield buf >> len
      buf &= ~(~0 << len)
      # puts "buf:   %0#{len}b (%d/%d)" % [buf, len, bitlen]
    end
  end

  def password length = PASSWORD_LENGTH, opts = {}
    source = opts[:source] || '/dev/urandom'
    chars  = opts[:chars ] || ASCII
    size   = chars.size
    bitlen = Math.log(size, 2).ceil
    buf    = []
    idx    = 0
    close  = false

    if source.is_a? String
      close = true
      source = File.open source, 'r'
    end

    stream source, bitlen do |n|
      next if n >= size
      buf[idx] = chars[n]
      break if (idx += 1) >= length
    end

    buf.join
  ensure
    source.close if close
  end
end
