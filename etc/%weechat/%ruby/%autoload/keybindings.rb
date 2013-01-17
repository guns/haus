# -*- encoding: utf-8 -*-
#
# Copyright (c) 2012 Sung Pae <self@sungpae.com>
# Distributed under the terms of the GNU General Public License v3.0.
# http://www.gnu.org/licenses/gpl-3.0.html

require 'weechat'
include Weechat
include Script::Skeleton

@script = {
  :name        => 'keybindings',
  :author      => 'guns <self@sungpae.com>',
  :version     => '1.0',
  :license     => 'GPL3',
  :gem_version => '0.0.5',
  :description => "Guns' personal keybindings"
}

CHANNELS = {
  :freenode => %w[
    #vim
    #clojure
    #archlinux
    #rxvt-unicode
    #archlinux-arm
    #leiningen
    #emacs
    #mutt
    #tmux
    #bash
    #git
    #nginx
    #openssl
    #ruby
    #ruby-lang
    ##English
  ],

  :mozilla => %w[
    #firefox
  ]
}

KEYBINDINGS = {
  'ctrl-C'      => '/window scroll_bottom',
  'ctrl-Cb'     => nil,
  'ctrl-Cc'     => nil,
  'ctrl-Ci'     => nil,
  'ctrl-Co'     => nil,
  'ctrl-Cr'     => nil,
  'ctrl-Cu'     => nil,
  'ctrl-X'      => nil,
  'ctrl-Xcf'    => '/shell -o echo "/connect freenode -password=$(pass irc/freenode-guns)"',
  'ctrl-Xcm'    => '/shell -o echo "/connect mozilla -password=$(pass irc/mozilla-guns)"',
  'ctrl-Xco'    => '/shell -o echo "/connect oftc -password=$(pass irc/oftc-guns)"',
  'ctrl-Xh'     => '/input insert /help',
  'ctrl-Xif'    => '/shell -o echo "/msg NickServ identify guns $(pass irc/freenode-guns)"',
  'ctrl-Xim'    => '/shell -o echo "/msg NickServ identify $(pass irc/mozilla-guns)"',
  'ctrl-Xio'    => '/shell -o echo "/msg NickServ identify $(pass irc/oftc-guns) guns"',
  'ctrl-Xj'     => nil,
  'ctrl-XJ'     => '/input insert /join #',
  'ctrl-Xjf'    => "/join -server freenode #{CHANNELS[:freenode].join ','}",
  'ctrl-Xjm'    => "/join -server freenode #{CHANNELS[:mozilla].join ','}",
  'ctrl-Xm'     => '/input insert /msg ',
  'ctrl-Xn'     => '/input insert /msg NickServ ',
  'ctrl-Xr'     => '/RELOADALL',
  'ctrl-Xs'     => '/input insert /list -re ',
  'ctrl-V'      => '/input grab_key_command',
  'meta-ctrl-?' => '/input delete_previous_word',
  'mod4-b'      => '/bar scroll nicklist * y-90%',
  'mod4-E'      => '/window page_down',
  'mod4-e'      => '/window scroll_down',
  'mod4-f'      => '/bar scroll nicklist * y+90%',
  'mod4-g'      => '/go',
  'mod4-j'      => '/buffer +1',
  'mod4-J'      => '/buffer move +1',
  'mod4-k'      => '/buffer -1',
  'mod4-K'      => '/buffer move -1',
  'mod4-p'      => '/window scroll_previous_highlight',
  'mod4-t'      => '/toggle_nicklist toggle',
  'mod4-U'      => '/input set_unread_current_buffer',
  'mod4-u'      => '/window scroll_unread',
  'mod4-x'      => '/input switch_active_buffer',
  'mod4-Y'      => '/window page_up',
  'mod4-y'      => '/window scroll_up',
  'mod4-\''     => '/input jump_smart',
  'mod4-\\'     => '/buffer close',
  'mod4-|'      => '/quit',
}

def bind key, val
  if val.nil?
    Weechat.exec '/mute /key unbind %s' % key
  else
    Weechat.exec '/mute /key bind %s %s' % [key, val]
  end
end

def bind_readline_unicode_chars
  inputrc = File.expand_path '~/.inputrc'

  if File.readable? inputrc
    # Ruby 1.8 series lacks both encoded strings and \h character class
    IO.readlines(inputrc).grep /"\\e(.)":\s*"(.+)".*\bU\+[0-9a-fA-F]{4,6}\b/ do
      bind "meta-#{$1}", '/input insert %s' % $2.unpack('U').pack('U')
    end
  end
end

def setup
  bind_readline_unicode_chars
  KEYBINDINGS.each { |key, val| bind key, val }
end
