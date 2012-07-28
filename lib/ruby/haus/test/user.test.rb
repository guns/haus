# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'tempfile'
require 'haus/user'
require 'haus/test/helper/minitest'
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

  describe :distrusts do
    before do
      @user = Haus::User.new $user.uid
    end

    it 'must accept one argument' do
      @user.method(:distrusts).arity.must_equal 1
    end

    it 'must raise ENOENT when given path does not exist' do
      lambda { @user.distrusts '/perfect/child' }.must_raise Errno::ENOENT
    end

    it 'must return a reason when path is not owned by user or root, is group-writable, or is world-writable' do
      # Non-test-user owned directory
      home_path = File.expand_path '~'
      home_stat = File.stat home_path
      home_stat.uid.wont_equal @user.uid
      (home_stat.mode & 0022).must_equal 0
      @user.distrusts(home_path).must_match /not owned by.*root/

      # Root-owned world-writable directory
      tmp_path = File.expand_path '/tmp'
      tmp_stat = File.stat tmp_path
      tmp_stat.uid.must_equal 0
      (tmp_stat.mode & 0002).must_equal 0002
      @user.distrusts(tmp_path).must_match /world writable/

      # Current-user owned group-writable directory
      user = Haus::User.new Etc.getlogin
      file_path = Tempfile.new(user.name).path
      file_stat = File.stat file_path
      file_stat.uid.must_equal user.uid
      FileUtils.chmod 0660, file_path
      user.distrusts(file_path).must_match /group writable/
    end

    it 'must return nil when a path is fully trusted' do
      user = Haus::User.new Etc.getlogin
      path = Tempfile.new(user.name).path
      stat = File.stat path
      stat.uid.must_equal user.uid
      FileUtils.chmod 0644, path
      user.distrusts(path).must_be_nil
    end

    it 'must check ACLs to see if the path is truly owner-write-only' do
      # TODO
    end
  end
end
