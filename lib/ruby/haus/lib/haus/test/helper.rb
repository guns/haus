# -*- encoding: utf-8 -*-

require 'fileutils'
require 'etc'
require 'minitest/unit'
require 'haus/task'

class Haus
  class Noop < Task; end
end

module MiniTest
  module Assertions
    def capture_fork_io
      out_rd, out_wr = IO.pipe
      err_rd, err_wr = IO.pipe

      pid = fork do
        out_rd.close
        err_rd.close
        $stdout.reopen out_wr
        $stderr.reopen err_wr
        yield
      end

      out_wr.close
      err_wr.close
      Process.wait pid
      [out_rd.read, err_rd.read]
    end
  end
end

class Haus
  #
  # Don't call TestUser#new, rather:
  #
  #   before do
  #     @user = Haus::TestUser[$$]
  #   end
  #
  # Certain methods trigger filesystem modifications, which are then scheduled
  # to be removed via Kernel::at_exit.
  #
  class TestUser < Struct::Passwd
    include FileUtils

    class << self
      attr_reader :list

      def [] key
        @list      ||= {}
        @list[key] ||= self.new
      end
    end

    attr_reader :haus

    def initialize
      name  = ENV['TEST_USER'] || 'test'
      entry = Etc.getpwnam name
      entry.members.each { |m| send "#{m}=", entry.send(m) }

      @haus = File.join dir, ".#{str 8}"

      abort "No privileges to write #{dir.inspect}" unless File.writable? dir
    rescue ArgumentError
      abort %Q{
        FAILURE: No such user #{name.inspect}
        FAILURE:
        FAILURE: This test suite requires a real Unix user account with a home
        FAILURE: directory writable by the current user. The name of the testing user
        FAILURE: is `test' by default, and can be changed by setting ENV['TEST_USER']
        FAILURE:
        FAILURE: All the files in the test user's home directory are at risk of being
        FAILURE: modified or destroyed.
      }.gsub(/^ +/, '')
    end

    def str len
      chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      'haus-' + (1..len).map { chars[rand chars.size] }.join
    end

    def etc
      File.join haus, 'etc'
    end

    # List of files in HAUS_PATH/etc/*
    def hausfiles
      @hausfiles ||= begin
        files = []
        mkdir_p etc

        # Create random files + directories
        Dir.chdir etc do
          4.times { f = str 8; touch f; files << File.expand_path(f) }
          4.times { f = File.join str(8), str(8); mkdir File.dirname(f); touch f; files << File.expand_path(f) }
        end

        at_exit { clean }

        files
      end
    end

    def clean
      rm_rf haus
      @haus, @hausfiles = nil, nil
    end
  end
end
