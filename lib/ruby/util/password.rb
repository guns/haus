# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

require 'digest/sha1'

module Util
  module Password
    extend self

    PASSWORD_LENGTH = 60
    ASCII = (0x21..0x7e).map &:chr # Printable non-whitespace characters
    ALPHA = ASCII.grep /[a-zA-Z0-9]/

    # Open a file and stream it to a block, `bit_len` bits at a time.
    #
    # Note that this is effectively an implementation of `rand(ceil)`, where
    # `ceil` is a power of 2 and the entropy source is an arbitrary file.
    #
    # Example:
    #
    #   count = 0
    #   stream '/dev/random', 12 do |n|
    #     puts '%4d: %012b' % [n, n]
    #     break if (count += 1) > 3
    #   end
    #
    # outputs:
    #
    #    301: 000100101101
    #   3446: 110101110110
    #   1847: 011100110111
    #   1921: 011110000001
    #
    def stream source, bit_len = 8
      buf = len = 0
      File.open source, 'r' do |f|
        loop do
          until len >= bit_len
            byte = f.getbyte
            raise 'Source reached EOF' if byte.nil?
            len += 8
            buf <<= 8
            buf |= byte
            # puts "byte:  %08b\nbuf:   %0#{len}b (%d/%d)\n" % [byte, buf, len, bit_len]
          end
          len -= bit_len
          # puts "FLUSH: %0#{bit_len}b" % (buf >> len)
          yield buf >> len
          buf &= ~(~0 << len)
          # puts "buf:   %0#{len}b (%d/%d)" % [buf, len, bit_len]
        end
      end
    end

    def password length = PASSWORD_LENGTH, opts = {}
      source   = opts[:source] || '/dev/urandom'
      chars    = opts[:chars ] || ASCII
      size     = chars.size
      bit_len  = Math.log(size, 2).ceil
      buf, idx = [], 0

      stream source, bit_len do |n|
        next if n >= size
        buf[idx] = chars[n]
        break if (idx += 1) >= length
      end

      buf.join
    end
  end
end
