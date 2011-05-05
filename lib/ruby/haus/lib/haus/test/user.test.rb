# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and RUBY_VERSION > '1.8.6'
require 'minitest/autorun'
require 'haus/user'
require 'haus/test/helper'

describe Haus::User do
  before do
    @user = Haus::TestUser[__FILE__]
  end

  it 'should be a subclass of Struct::Passwd' do
    Haus::User.new.must_be_kind_of Struct::Passwd
  end

  describe :initialize do
    it 'should accept a single optional argument' do
      Haus::User.new.method(:initialize).arity.must_equal -1
    end

    it 'should default to the current user' do
      Haus::User.new.name.must_equal ENV['USER']
    end

    it 'should accept the name of a user as a string' do
      Haus::User.new(@user.name).uid.must_equal @user.uid
    end

    it 'should accept the UID of a user' do
      Haus::User.new(@user.uid).name.must_equal @user.name
    end
  end
end
