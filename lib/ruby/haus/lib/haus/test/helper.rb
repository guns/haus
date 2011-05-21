# -*- encoding: utf-8 -*-

require 'fileutils'
require 'etc'
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
  #     @user = Haus::TestUser[__FILE__]
  #   end
  #
  # Certain methods trigger filesystem modifications, which are then scheduled
  # to be removed via Kernel::at_exit.
  #
  class TestUser < Struct::Passwd
    class << self
      attr_reader :list

      def [] key
        @list      ||= {}
        @list[key] ||= self.new
      end
    end

    def initialize
      unless $warned
        puts %Q{\
          WARNING: This test suite requires a real Unix user account with a home
          WARNING: directory writable by the current user. The name of the testing user
          WARNING: is `test' by default, and can be changed by setting ENV['TEST_USER']
          WARNING:
          WARNING: All the files in the test user's home directory are at risk of being
          WARNING: modified or destroyed.\n
        }.gsub(/^ +/, '')
        $warned = true
      end

      name  = ENV['TEST_USER'] || 'test'
      entry = Etc.getpwnam name
      entry.members.each { |m| send "#{m}=", entry.send(m) }

      abort "No privileges to write #{dir.inspect}" unless File.writable? dir
    rescue ArgumentError
      abort "No such user #{name.inspect}"
    end

    def str len
      chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      (1..len).map { chars[rand chars.size] }.join
    end

    def haus
      @haus ||= File.join dir, '.haus-' + str(8)
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
          4.times { f = [str(8), str(8)].join '/'; mkdir File.dirname(f); touch f; files << File.expand_path(f) }
        end

        Kernel.at_exit { clean }

        files
      end
    end

    def clean
      rm_rf haus
      @haus, @hausfiles = nil, nil
    end
  end
end
