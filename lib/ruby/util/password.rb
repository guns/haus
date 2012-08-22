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
    ASCII = (0x20..0x7e).map &:chr # Printable characters only
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
          chr = f.getc
          break if chr.nil?
          # Using a BitSet here would be less wasteful than using chars
          buf << '%08b' % chr.unpack('C') until buf.length >= bit_len
          yield buf.slice!(0, bit_len).to_i(2)
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

    def npass_0 len = 40, sec = tty_secret, buf = tty_buffer
      pass = [sec, buf].map { |s| Digest::SHA1.hexdigest s }.join
      pass *= 2 until pass.length >= len
      pass[0, len]
    end

    def npass_1 len = 81, sec = tty_secret, buf = tty_buffer
      # Create salt by least occurrence and last appearance
      salt = (sec + buf).chars.inject({}) do |h, ch|
        next h if ch =~ /\s/
        h[ch] ||= 0
        h[ch]  += 1
        h
      end.sort_by { |ch, n| n }.take(8).map(&:first).join

      # Create password from different permutations of sec, buf, and salt
      pass = [sec + buf, buf + sec, salt.reverse + sec + buf].map do |str|
        Digest::SHA1.base64digest(str + salt).chomp '='
      end.join

      pass *= 2 until pass.length > len
      pass[0, len]
    end

    private

    # Get a passphrase from the terminal
    def tty_secret
      raise 'stdin is not a terminal!' unless $stdin.tty?
      raise '`stty` is unavailable!' unless system 'command -v stty &>/dev/null'

      $stderr.print 'Secret:'
      state = %x(stty -g).chomp
      system 'stty -echo'

      $stdin.readline.chomp rescue ''
    ensure
      system 'stty', state
      warn '####'
    end

    # Get a string from the terminal
    def tty_buffer
      raise 'stdin is not a terminal!' unless $stdin.tty?
      ($stdin.gets nil rescue '') || ''
    end
  end
end
