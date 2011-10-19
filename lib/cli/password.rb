# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

module CLI
  module Password
    PASSWORD_LENGTH = 60
    ASCII = (0x20..0x7e).map &:chr
    ALPHA = ASCII.grep /[a-zA-Z0-9]/

    # Open a file and stream it to a block, `bit_len` bits at a time. This is
    # done in a relatively expensive fashion, based on the assumption that the
    # entropy in the file is more precious than clock cycles.
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
      buf = ''
      File.open source, 'r' do |f|
        loop do
          buf << '%08b' % f.getc.unpack('C') until buf.length >= bit_len
          yield buf.slice!(0, bit_len).to_i(2)
        end
      end
    end
    module_function :stream

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
    module_function :password
  end
end
