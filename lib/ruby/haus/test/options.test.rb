# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'haus/options'
require 'haus/test/helper/minitest'
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
      ostruct.path.must_equal File.expand_path('../../../../..', __FILE__)
      ostruct.logger.must_be_kind_of Haus::Logger
    end

    it 'must set @ostruct.debug to true if ENV["DEBUG"]' do
      capture_fork_io do
        puts Haus::Options.new.debug == false
        ENV['DEBUG'] = '1'
        puts Haus::Options.new.debug == true
      end.first.must_equal "true\ntrue\n"
    end

    it 'must accept one optional Hash argument like OpenStruct' do
      o = Haus::Options.new :funcdef => :parity
      o.funcdef.must_equal :parity
    end

    it 'must accept up to three arguments like OptionParser' do
      o = Haus::Options.new 'Hello World', 42, '****'
      o.banner.must_equal 'Hello World'
      o.summary_width.must_equal 42
      o.summary_indent.must_equal '****'
    end

    it 'must maintain parameter equivalent with OptionParser' do
      compare_params = lambda do |a, b|
        %w[banner summary_width summary_indent].each { |attr| a.send(attr).must_equal b.send(attr) }
      end

      compare_params.call Haus::Options.new(nil),             OptionParser.new(nil)
      compare_params.call Haus::Options.new(nil, 16),         OptionParser.new(nil, 16)
      compare_params.call Haus::Options.new(nil, nil, '-> '), OptionParser.new(nil, nil, '-> ')
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
