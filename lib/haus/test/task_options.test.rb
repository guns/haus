# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/task_options'
require 'haus/test/helper/minitest'

class Haus::TaskOptionsSpec < MiniTest::Spec
  before do
    @opt = Haus::TaskOptions.new
  end

  it 'must be a subclass of Haus::Options' do
    @opt.class.ancestors[1].must_equal Haus::Options
  end

  describe :users= do
    it 'must set the users option' do
      users     = [0, Etc.getlogin]
      haususers = users.map { |u| Haus::User.new u }

      @opt.users = users
      @opt.instance_variable_get(:@ostruct).users.must_equal haususers
      @opt.users.must_equal haususers
    end
  end
end
