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
  :version     => '0.1',
  :license     => 'GPL3',
  :gem_version => '0.0.5',
  :description => "Guns' personal keybindings"
}

CHANNELS = %w[
  #vim
  #mutt
  #clojure
  #leiningen
  #tmux
  ##English
  #bash
  #git
  #nginx
  #openssl
  #rxvt-unicode
  #ruby
  #ruby-lang
  #RubyOnRails
]

KEYBINDINGS = {
  'ctrl-C'      => '/window scroll_bottom',
  'ctrl-V'      => '/input grab_key_command',
  'meta-ctrl-?' => '/input delete_previous_word',
  'meta-j'      => '/input insert /join #',
  'meta-s'      => '/input insert /list -re',
  'mod4-b'      => '/bar scroll nicklist * y-90%',
  'mod4-C'      => '/connect freenode',
  'mod4-ctrl-M' => "/join #{CHANNELS.join ','}",
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
  'mod4-Y'      => '/window page_up',
  'mod4-y'      => '/window scroll_up',
  'mod4-\''     => '/input jump_smart',
  'mod4-\\'     => '/buffer close',
  'mod4-|'      => '/quit',
}

def bind key, val
  Weechat.exec '/mute /key bind %s %s' % [key, val]
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
