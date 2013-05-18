# -*- encoding: utf-8 -*-

class Haus
  #
  # Simple terminal-oriented logging class.
  #
  class Logger
    class << self
      def italics?
        system '/bin/sh -c "command -v tput && tput sitm" &>/dev/null'
      end

      def colors256?
        system '/bin/sh -c "command -v tput && test \"$(tput colors)\" -eq 256" &>/dev/null'
      end
    end

    # ANSI SGR codes
    # http://www.inwap.com/pdp10/ansicode.txt
    # http://en.wikipedia.org/wiki/ANSI_escape_code#graphics
    SGR = Hash.new { |h,k| k.is_a?(Symbol) ? h.fetch(k) : k.to_s }.merge({
      :reset      => '0',  :clear       => '0',  :normal => '0',
      :bold       => '1',  :nobold      => '21',
      :dim        => '2',  :nodim       => '22',
      :italic     => '3',  :noitalic    => '23',
      :underline  => '4',  :nounderline => '24',
      :slowblink  => '5',  :noblink     => '25',
      :rapidblink => '6',
      :reverse    => '7',  :noreverse   => '27',
      :conceal    => '8',  :noconceal   => '28',
      :strikeout  => '9',  :nostrikeout => '29',
      :fraktur    => '20', :nofraktur   => '23',
      :black      => '30', :BLACK       => '40',
      :red        => '31', :RED         => '41',
      :green      => '32', :GREEN       => '42',
      :yellow     => '33', :YELLOW      => '43',
      :blue       => '34', :BLUE        => '44',
      :magenta    => '35', :MAGENTA     => '45',
      :cyan       => '36', :CYAN        => '46',
      :white      => '37', :WHITE       => '47',
      :default    => '39', :DEFAULT     => '49',
      :frame      => '51', :noframe     => '54',
      :encircle   => '52', :noencircle  => '54',
      :overline   => '53', :nooverline  => '55',
      :ideogram_underline        => '60',
      :ideogram_double_underline => '61',
      :ideogram_overline         => '62',
      :ideogram_double_overline  => '63',
      :ideogram_stress           => '64'
    })

    # Xterm 256-color table
    256.times do |n|
      SGR["x#{n}".to_sym] = "38;5;#{n}"
      SGR["X#{n}".to_sym] = "48;5;#{n}"
    end

    attr_accessor :io

    def initialize io = $stdout
      @io = io
    end

    def sgr msg, *styles
      return msg if not io.tty?
      "\e[%sm%s\e[0m" % [styles.map { |s| SGR[s] }.join(';'), msg]
    end

    # Parameters are either strings, or lists that begin with a string and are
    # followed by SGR codes.
    #
    #   fmt ['!!', :red, :bold], ' DANGER!' # => "\e[31;1m!!\e[0m DANGER!"
    #
    def fmt *args
      args.map { |arg| arg.is_a?(Array) ? sgr(*arg) : arg }.join
    end

    def log *args
      io.puts fmt(*args)
    end
  end

  #
  # Example:
  #
  #   class MyApp
  #     include Haus::Loggable
  #
  #     def initialize
  #       logger.io = $stderr
  #     end
  #
  #     def info msg
  #       log [msg, :italic]
  #     end
  #
  #     def colorize msg, *styles
  #       fmt [msg, *styles]
  #     end
  #   end
  #
  module Loggable
    def logger
      @__haus_logger__ ||= Haus::Logger.new
    end
    alias :__logger__ :logger

    def log *args
      __logger__.log *args
    end

    def fmt *args
      __logger__.fmt *args
    end
  end
end
