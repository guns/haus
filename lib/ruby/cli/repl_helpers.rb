# -*- encoding: utf-8 -*-
#
# Copyright (c) 2012 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

module CLI
  module ReplHelpers
    # Invoke interactive_editor or Pry edit
    def edit *args
      ::CLI::ReplHelpers.send :remove_method, :edit
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
        require 'util/notification'
        Util::Notification.new :audio => File.expand_path('~/.local/sounds/message-received.mp3')
      end
      @notify.call; nil
    end
    alias :na :notify

    # Toggle number inspect style
    def toggle_verbose_numbers
      [Fixnum, Bignum].each do |klass|
        klass.module_eval do
          class << self
            attr_accessor :verbose_inspect
          end

          if self.verbose_inspect = !verbose_inspect
            alias_method :__inspect__, :inspect
            def inspect
              hex = '%x' % self
              hex = '0' + hex unless hex.length.even?
              bin = '%04b' % self
              '%d 0%0o 0x%s (%s)' % [self, self, hex, bin.reverse.scan(/\d{1,4}/).join(' ').reverse]
            end
          else
            remove_method :inspect
            alias_method :inspect, :__inspect__
          end
        end
      end
    end
  end
end
