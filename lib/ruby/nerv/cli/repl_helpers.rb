# -*- encoding: utf-8 -*-
#
# Copyright (c) 2012 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

module NERV; end
module NERV::CLI; end

module NERV::CLI::ReplHelpers
  # Invoke interactive_editor or Pry edit
  def edit *args
    ::NERV::CLI::ReplHelpers.send :remove_method, :edit
    unless $0 == 'pry'
      require 'interactive_editor'
      alias :edit :vim
      vim *args
    end
  end

  # Pretty print, returning nil
  def pp *args
    require 'pp'
    super
    nil
  end

  # Awesome print, returning nil
  def ap *args
    require 'ap'
    super
    nil
  end

  # http://stackoverflow.com/questions/123494/whats-your-favourite-irb-trick/123834#123834
  def bm n = 1
    require 'benchmark'
    warn "#{n} iteration(s):"
    Benchmark.bm do |test|
      test.report { n.times { yield } }
    end; nil
  end

  def notify
    @notify ||= begin
      require 'nerv/util/notification'
      NERV::Util::Notification.new :audio => File.expand_path('~/.local/sounds/message-received.mp3')
    end
    @notify.call; nil
  end
  alias :na :notify

  def slurp path
    File.read path
  end

  def spit path, buf
    File.open(path, 'w') { |f| f.write buf }
  end

  # Toggle number inspect style
  def toggle_verbose_numbers
    [Fixnum, Bignum].each do |klass|
      klass.module_eval do
        class << self
          attr_accessor :verbose_inspect
        end

        if self.verbose_inspect = !verbose_inspect
          alias_method :__inspect__, :inspect

          def bin
            buf = '%04b' % self
            n = buf.size % 4
            ('0' * (n.zero? ? 0 : 4 - n) << buf).scan(/\d{4}/).join ' '
          end

          def inspect
            hex = '%x' % self
            hex = '0' + hex unless hex.length.even?
            '%d 0%0o 0x%s (%s)' % [self, self, hex, bin]
          end
        else
          remove_method :bin
          remove_method :inspect
          alias_method :inspect, :__inspect__
        end
      end
    end
  end
end
