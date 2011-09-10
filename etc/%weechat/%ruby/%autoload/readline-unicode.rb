# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the terms of the GNU General Public License v3.0.
# http://www.gnu.org/licenses/gpl-3.0.html

require 'weechat'
include Weechat
include Script::Skeleton

@script = {
  :name        => 'readline-unicode',
  :author      => 'guns <self@sungpae.com>',
  :version     => '0.1',
  :license     => 'GPL3',
  :gem_version => '0.0.5',
  :description => 'Permanently import readline Unicode character bindings from ~/.inputrc'
}

INPUTRC = File.expand_path '~/.inputrc'

def setup
  raise 'No user readline initialization file found.' unless File.readable? INPUTRC

  # Ruby 1.8 series lacks both encoded strings and \h character class
  IO.readlines(INPUTRC).grep /"\\e(.)":\s*"(.+)".*\bU\+[0-9a-fA-F]{4,6}\b/ do
    bind = "meta-#{$1}"
    char = $2.unpack('U').pack 'U'
    Weechat.exec "/mute key bind #{bind} /input insert #{char}"
  end
end
