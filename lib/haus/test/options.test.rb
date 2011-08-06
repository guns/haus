# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/options'
require 'haus/test/helper/test_user'

$user ||= Haus::TestUser[$$]

class Haus::OptionsSpec < MiniTest::Spec
  before do
    @opt = Haus::Options.new
  end

  it 'must be a subclass of OptionParser' do
    @opt.must_be_kind_of OptionParser
  end

  describe :initialize do
    it 'must initialize @ostruct' do
      ostruct = @opt.instance_variable_get :@ostruct
      ostruct.must_be_kind_of OpenStruct
      ostruct.path.must_be_kind_of String
      ostruct.path.must_equal File.expand_path('../../../..', __FILE__)
      ostruct.logger.must_be_kind_of Haus::Logger
    end
  end

  describe :path do
    it 'must always return an absolute path' do
      ostruct = @opt.instance_variable_get :@ostruct
      ostruct.path.must_match %r{\A/}
      @opt.path = '..'
      ostruct.path.must_match %r{\A/}
    end
  end

  describe :method_missing do
    it 'must otherwise act like an OpenStruct object' do
      @opt.force = true
      @opt.force.must_equal true
      @opt.horse = 'of course'
      @opt.horse.must_equal 'of course'
      @opt.norse = 'Viking'
      @opt.norse.must_equal 'Viking'
    end
  end

  describe :tap do
    it 'must respond to #tap, which should behave like Ruby 1.9 Object#tap' do
      @opt.must_respond_to :tap
      @opt.tap { |o| o.must_equal @opt }.must_equal @opt
    end
  end
end
