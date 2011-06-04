# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/link'
require 'haus/test/helper/test_user'

$user = Haus::TestUser[$$]

describe Haus::Link do
  describe :enqueue do
    before do
      @link = Haus::Link.new
      $user.hausfile :file
      $user.hausfile :dir
      $user.hausfile :link
    end

    it 'should add link jobs to the queue' do
      @link.options.path = $user.haus
      @link.options.users = [ENV['TEST_USER'] || 'test']
      @link.enqueue
    end
  end
end
