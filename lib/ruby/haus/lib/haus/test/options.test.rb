# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and RUBY_VERSION > '1.8.6'
require 'minitest/autorun'
require 'haus/options'

describe Haus::Options do
  it 'should be a subclass of OptionParser' do
    Haus::Options.new.must_be_kind_of OptionParser
  end

  describe :initialize do
    it 'should set @ostruct.path' do
      opt = Haus::Options.new
      ostruct = opt.instance_variable_get :@ostruct
      ostruct.must_be_kind_of OpenStruct
      ostruct.path.must_be_kind_of String
      ostruct.path.must_equal File.expand_path('../../../../..', __FILE__)
    end
  end

  describe :method_missing do
    it 'should otherwise act like an OpenStruct object' do
      opt = Haus::Options.new
      opt.force = true
      opt.force.must_equal true
      opt.horse = 'of course'
      opt.horse.must_equal 'of course'
      opt.norse = 'Viking'
      opt.norse.must_equal 'Viking'
    end
  end

  describe :tap do
    it 'should respond to #tap, which should behave like Ruby 1.9 Object#tap' do
      Haus::Options.new.must_respond_to :tap
      opt = Haus::Options.new
      opt.tap { |o| o.must_equal opt }.must_equal opt
    end
  end
end
