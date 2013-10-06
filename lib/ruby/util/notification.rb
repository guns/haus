# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

module Util
  class Notification
    attr_accessor :message, :title, :sticky, :audio

    def initialize opts = {}
      @message = opts[:message] || 'Attention'
      @title   = opts[:title]
      @sticky  = opts[:sticky]
      @audio   = opts[:audio] || :voice
    end

    def have cmd
      system %Q(/bin/sh -c 'command -v #{cmd}' >/dev/null 2>&1)
    end

    def forkexec *args
      Process.detach fork {
        [$stdout, $stderr].each { |fd| fd.reopen '/dev/null' }
        exec *args
      }
    end

    def notify
      if have 'growlnotify'
        cmd  = %W[growlnotify -m #{message}]
        cmd += %W[--title #{title}] if title
        cmd += %w[--sticky] if sticky
        forkexec *cmd
      elsif have 'notify-send'
        forkexec 'notify-send', *[title, message].compact
      end
    end

    def play
      return unless audio

      if audio == :voice
        if RUBY_PLATFORM =~ /darwin/i and have 'say'
          forkexec 'say', message
        elsif have 'festival'
          Process.detach fork { IO.popen('festival --tts', 'w') { |io| io.puts message } }
        elsif have 'espeak'
          forkexec 'espeak', message
        end
      elsif File.readable? audio
        if have 'afplay'
          forkexec 'afplay', audio
        elsif have 'play'
          forkexec 'play', '-q', audio
        end
      end
    end

    def call
      pool = []
      %w[play notify].each do |m|
        pool << Thread.new { send m }
      end
      pool.each &:join
    end
  end
end
