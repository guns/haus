# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/user'
require 'haus/test/helper/test_user'

$user ||= Haus::TestUser[$$]

class Haus::UserSpec < MiniTest::Spec
  it 'must be a subclass of Struct::Passwd' do
    Haus::User.new.must_be_kind_of Struct::Passwd
  end

  describe :initialize do
    it 'must accept a single optional argument' do
      Haus::User.new.method(:initialize).arity.must_equal -1
    end

    it 'must default to the current user' do
      Haus::User.new.name.must_equal Etc.getlogin
    end

    it 'must accept the name of a user as a string' do
      Haus::User.new($user.name).uid.must_equal $user.uid
    end

    it 'must accept the UID of a user as a fixnum' do
      Haus::User.new($user.uid).name.must_equal $user.name
    end

    it 'must raise an error otherwise' do
      lambda { Haus::User.new /root/ }.must_raise ArgumentError
    end
  end

  describe :dot do
    it 'must return a path as a home dotfile path' do
      Haus::User.new($user.name).dot('/etc/passwd').must_equal "#{$user.dir}/.passwd"
    end
  end

  describe :dotfiles do
    it 'must return all dotfiles in user home directory' do
      my_dotfiles = Dir[File.expand_path '~/.*'].reject { |f| File.basename(f) =~ /\A\.{1,2}\z/ }
      Haus::User.new(Etc.getlogin).dotfiles.sort.must_equal my_dotfiles.sort

      her_dotfiles = Dir[File.expand_path File.join("#{$user.dir}/.*")].reject { |f| File.basename(f) =~ /\A\.{1,2}\z/ }
      Haus::User.new($user.name).dotfiles.sort.must_equal her_dotfiles.sort
    end
  end
end
