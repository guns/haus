# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011-2017 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

require 'cgi'

module NERV; end
module NERV::Util; end

class NERV::Util::Notification
  PRESETS = {
    'alert' => {
      :title   => nil,
      :message => 'Attention',
      :audio   => File.expand_path('~/.local/share/sounds/alert.ogg'),
      :icon    => nil,
      :sticky  => false,
    },
    'warning' => {
      :title   => 'Warning',
      :message => nil,
      :audio   => File.expand_path('~/.local/share/sounds/warning.ogg'),
      :icon    => 'dialog-warning',
      :sticky  => false,
    },
    'success' => {
      :title   => 'Success',
      :message => nil,
      :audio   => File.expand_path('~/.local/share/sounds/success.ogg'),
      :icon    => 'dialog-ok',
      :sticky  => false,
    },
    'error' => {
      :title   => 'Error',
      :message => nil,
      :audio   => File.expand_path('~/.local/share/sounds/error.ogg'),
      :icon    => 'dialog-error',
      :sticky  => false,
    },
    'new-mail' => {
      :title   => 'New mail',
      :message => nil,
      :audio   => File.expand_path('~/.local/share/sounds/new-mail.ogg'),
      :icon    => 'mail',
      :sticky  => false,
    },
    'battery-low' => {
      :title   => 'Caution',
      :message => 'Battery low',
      :audio   => File.expand_path('~/.local/share/sounds/battery-low.ogg'),
      :icon    => 'battery-caution',
      :sticky  => false,
    }
  }

  attr_accessor :message, :title, :sticky, :audio, :icon

  def initialize opts = {}
    @audio   = :voice
    apply_preset opts[:preset] if opts[:preset]
    @title   = opts[:title]    if opts.has_key? :title
    @message = opts[:message]  if opts.has_key? :message
    @sticky  = opts[:sticky]   if opts.has_key? :sticky
    @audio   = opts[:audio]    if opts.has_key? :audio
    @icon    = opts[:icon]     if opts.has_key? :icon
  end

  def apply_preset key
    preset   = PRESETS[key]
    @title   = preset[:title]
    @message = preset[:message]
    @audio   = preset[:audio]
    @icon    = preset[:icon]
    @sticky  = preset[:sticky]
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
    if have 'notify-send'
      cmd = %W[notify-send]
      cmd << '--urgency=critical' if sticky
      cmd << "--icon=#{icon}" if icon
      cmd << title if title and not title.empty?
      cmd << CGI.escape_html(message.to_s)
      forkexec *cmd
    elsif have 'growlnotify'
      cmd  = %W[growlnotify -m #{message}]
      cmd += %W[--title #{title}] if title
      cmd << '--sticky' if sticky
      forkexec *cmd
    end
  end

  def play
    return unless audio

    if audio == :voice
      if have 'espeak'
        forkexec 'espeak', message
      end
    elsif File.readable? audio
      if have 'play'
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
