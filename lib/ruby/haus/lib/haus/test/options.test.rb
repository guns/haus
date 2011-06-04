# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/options'
require 'haus/test/helper/test_user'

$user = Haus::TestUser[$$]

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
    end
  end

  describe :etc do
    it 'should return HAUS_PATH/etc' do
      @opt.etc.must_equal File.join(@opt.path, 'etc')
      @opt.path = '/tmp/haus'
      @opt.etc.must_equal '/tmp/haus/etc'
    end
  end

  describe :etcfiles do
    it 'should return all files in HAUS_PATH/etc/*' do
      files = []
      $user.hausfile :file
      $user.hausfile :dir
      $user.hausfile :link

      # Awkward select via each_with_index courtesy of Ruby 1.8.6
      $user.instance_variable_get(:@hausfiles).each_with_index do |f, i|
        files << f if (i % 2).zero?
      end

      @opt.path = $user.haus
      @opt.etcfiles.sort.must_equal files.sort
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
