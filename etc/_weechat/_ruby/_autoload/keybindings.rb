# -*- encoding: utf-8 -*-
#
# Copyright (c) 2012-2017 Sung Pae <self@sungpae.com>
# Distributed under the terms of the GNU General Public License v3.0.
# http://www.gnu.org/licenses/gpl-3.0.html

require 'rubygems'
require 'weechat'
require 'yaml'
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

CHANNELS = YAML.load_file File.expand_path('~/.weechat/channels.yml')

KEYBINDINGS = {
  'default' => {
    'ctrl-C'      => '/window scroll_bottom',
    'ctrl-Cb'     => nil,
    'ctrl-Cc'     => nil,
    'ctrl-Ci'     => nil,
    'ctrl-Co'     => nil,
    'ctrl-Cr'     => nil,
    'ctrl-Cu'     => nil,
    'ctrl-L'      => '/input hotlist_clear;/window refresh',
    'ctrl-O'      => '/input jump_previously_visited_buffer',
    'ctrl-]'      => '/input delete_line',
    'meta-o'      => '/input jump_next_visited_buffer',
    'ctrl-_'      => '/input undo',
    'ctrl-R'      => '/input redo',
    'mod4-/'      => '/input search_text',
    'mod4-\''     => '/input jump_smart',
    'mod4-p'      => '/window scroll_previous_highlight',
    'mod4-x'      => '/input switch_active_buffer',
    'mod4-X'      => '/input zoom_merged_buffer',
    'ctrl-X'      => nil,
    'ctrl-Xcf'    => '/exec -sh -o echo "/connect freenode -password=$(pass irc/freenode-guns)"',
    'ctrl-Xcm'    => '/exec -sh -o echo "/connect mozilla -password=$(pass irc/mozilla-guns)"',
    'ctrl-Xco'    => '/exec -sh -o echo "/connect oftc"',
    'ctrl-Xh'     => '/input insert /help',
    'ctrl-Xif'    => '/exec -sh -o echo "/msg NickServ identify guns $(pass irc/freenode-guns)"',
    'ctrl-Xim'    => '/exec -sh -o echo "/msg NickServ identify $(pass irc/mozilla-guns)"',
    'ctrl-Xio'    => '/exec -sh -o echo "/msg NickServ identify $(pass irc/oftc-guns) guns"',
    'ctrl-Xj'     => nil,
    'ctrl-XJ'     => '/input insert /join #',
    'ctrl-Xjf'    => "/join -server freenode #{CHANNELS[:freenode].join ','}",
    'ctrl-Xjm'    => "/join -server mozilla #{CHANNELS[:mozilla].join ','}",
    'ctrl-Xm'     => '/input insert /msg ',
    'ctrl-Xn'     => '/input insert /msg NickServ ',
    'ctrl-Xr'     => '/RELOADALL',
    'ctrl-Xs'     => '/input insert /list -re ',
    'ctrl-V'      => '/input grab_key_command',
    'meta-ctrl-?' => '/input delete_previous_word',
    'mod4-e'      => '/window scroll_down',
    'mod4-y'      => '/window scroll_up',
    'mod4-E'      => '/window page_down',
    'mod4-Y'      => '/window page_up',
    'mod4-b'      => '/bar scroll nicklist * y-90%',
    'mod4-f'      => '/bar scroll nicklist * y+90%',
    'mod4-g'      => '/go',
    'mod4-i'      => '/toggle_nicklist toggle',
    'mod4-j'      => '/buffer +1',
    'mod4-J'      => '/buffer move +1',
    'mod4-+'      => '/buffer move +1',
    'mod4-k'      => '/buffer -1',
    'mod4-K'      => '/buffer move -1',
    'mod4-_'      => '/buffer move -1',
    'mod4-U'      => '/input set_unread_current_buffer',
    'mod4-u'      => '/window scroll_unread',
    'mod4-\\'     => '/buffer close',
    'mod4-|'      => '/quit',
  },
  'search' => {
    'ctrl-C' => '/input search_stop',
    'ctrl-I' => '/input search_switch_where',
    'ctrl-O' => '/input search_switch_case',
    'ctrl-J' => '/input search_previous',
    'ctrl-M' => '/input search_previous',
    'ctrl-R' => '/input search_switch_regex',
    'ctrl-P' => '/input search_previous',
    'ctrl-N' => '/input search_next',
  }
}

def bind context, key, cmd
  if cmd.nil?
    Weechat.exec "/mute /key unbindctxt #{context} #{key}"
  else
    Weechat.exec "/mute /key bindctxt #{context} #{key} #{cmd}"
  end
end

def bind_readline_unicode_chars
  inputrc = File.expand_path '~/.inputrc.d/utf-8'

  if File.readable? inputrc
    # Ruby 1.8 lacks encoded strings
    IO.readlines(inputrc).grep /\A"\\e(.)": "(.+)"/ do
      bind 'default', "meta-#{$1}", '/input insert %s' % $2.unpack('U').pack('U')
    end
  end
end

def setup
  bind_readline_unicode_chars
  KEYBINDINGS.each do |context, bindings|
    bindings.each do |key, cmd|
      bind context, key, cmd
    end
  end
end
