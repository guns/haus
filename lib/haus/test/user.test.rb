# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'tempfile'
require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if [].respond_to? :cycle
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

  describe :hier do
    it 'must return a hierfile path as a home dotfile path' do
      feh_themes = Haus::User.new($user.name).hier "#{$user.etc}/%config/%feh/themes", $user.etc
      feh_themes.must_equal "#{$user.dir}/.config/feh/themes"
    end
  end

  describe :trusts? do
    before do
      @user = Haus::User.new $user.uid
    end

    it 'must accept one argument' do
      @user.method(:trusts?).arity.must_equal 1
    end

    it 'must raise ENOENT when given path does not exist' do
      lambda { @user.trusts? '/perfect/child' }.must_raise Errno::ENOENT
    end

    it 'must return false when a path is not owned by the user or by root' do
      # Test root and current user (non-test!) home directories
      [0, Etc.getlogin].map { |n| Haus::User.new n }.each do |user|
        path = user.dir
        stat = File.lstat path
        stat.ftype.must_equal 'directory'
        stat.uid.must_equal user.uid
        (stat.mode & 0022).must_equal 0
        @user.trusts?(path).must_equal stat.uid.zero?
      end
    end

    it 'must return false when a path is not solely writable by the user or by root' do
      # Root-owned, world-writable directory
      path = '/tmp'
      stat = File.stat path # Not :lstat; /tmp is sometimes a symlink
      stat.ftype.must_equal 'directory'
      stat.uid.must_equal 0
      (stat.mode & 0022).wont_equal 0
      @user.trusts?(path).must_equal false
    end

    it 'must check ACLs to see if the path is truly owner-write-only' do
      # TODO
    end
  end
end
