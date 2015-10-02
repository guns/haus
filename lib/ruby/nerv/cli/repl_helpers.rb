# -*- encoding: utf-8 -*-
#
# Copyright (c) 2012-2015 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

module NERV; end
module NERV::CLI; end

module NERV::CLI::ReplHelpers
  unless $0 == 'pry'
    def pry
      require 'pry'
      binding.send $stdin.tty? ? :pry : :remote_pry
    end

    # Invoke interactive_editor or Pry edit
    def edit *args
      ::NERV::CLI::ReplHelpers.send :remove_method, :edit
      require 'interactive_editor'
      alias :edit :vim
      vim *args
    end
  end

  # We often drop into a ruby console to act as a command shell
  def listfiles pat = '*', opts = {}
    Dir.glob(pat, ::File::FNM_DOTMATCH).reject { |f| f =~ /\A\.{1,2}\z/ }
  end
  alias :ls :listfiles unless defined? Pry
  alias :fs :listfiles
  alias :sh :system

  # View integers as dec, oct, hex, and bin
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

  # Pretty print, returning nil
  def pp *args
    require 'pp'
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

  def slurp path
    if path =~ %r{\A\w+://}
      IO.popen(['curl', '--user-agent', 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36', '--progress-bar', '--location', path]) { |io| io.read }
    else
      File.read path
    end
  end

  def spit path, buf
    File.open(path, 'w') { |f| f.write buf }
  end

  # Nokogiri shortcuts
  def noko buf
    require 'nokogiri'
    Nokogiri::HTML.parse buf
  end

  def nokoslurp path
    noko slurp(path)
  end

  def uri x
    require 'uri'
    URI.parse x
  end
end
