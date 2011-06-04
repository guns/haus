# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/options'

describe Haus::Options do
  before do
    @opt = Haus::Options.new
  end

  it 'should be a subclass of OptionParser' do
    @opt.must_be_kind_of OptionParser
  end

  describe :initialize do
    it 'should initialize @ostruct' do
      ostruct = @opt.instance_variable_get :@ostruct
      ostruct.must_be_kind_of OpenStruct
      ostruct.path.must_be_kind_of String
      ostruct.path.must_equal File.expand_path('../../../../../../..', __FILE__)
      ostruct.users.must_be_kind_of Array
      ostruct.users.first.must_be_kind_of Haus::User
      ostruct.users.must_equal [Haus::User.new]
    end
  end

  describe :users= do
    it 'should set the users option' do
      assert_raises(NoMethodError) { @opt.users = 'root' }
      users     = [0, Etc.getlogin]
      haususers = users.map { |u| Haus::User.new u }

      @opt.users = users
      @opt.instance_variable_get(:@ostruct).users.must_equal haususers
      @opt.users.must_equal haususers
    end
  end

  describe :method_missing do
    it 'should otherwise act like an OpenStruct object' do
      @opt.force = true
      @opt.force.must_equal true
      @opt.horse = 'of course'
      @opt.horse.must_equal 'of course'
      @opt.norse = 'Viking'
      @opt.norse.must_equal 'Viking'
    end
  end

  describe :tap do
    it 'should respond to #tap, which should behave like Ruby 1.9 Object#tap' do
      @opt.must_respond_to :tap
      @opt.tap { |o| o.must_equal @opt }.must_equal @opt
    end
  end
end
