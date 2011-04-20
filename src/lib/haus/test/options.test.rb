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

  it 'should respond to #tap' do
    Haus::Options.new.must_respond_to :tap
  end

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
