# -*- encoding: utf-8 -*-

require 'fileutils'
require 'etc'
require 'expect'
require 'minitest/unit'
require 'haus/task'

class Haus
  class Noop < Task; end
  class Noop2 < Task; end
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

    def with_no_stdin
      $stdin.reopen '/dev/null'
      yield
    ensure
      $stdin.reopen STDIN
    end

    def with_filetty
      fin, fout = [rand, rand].map do |n|
        f = File.open "/tmp/haus-filetty-#{n}", 'w+'
        f.instance_eval do
          def tty?
            true
          end
          alias :isatty :tty?

          # FileUtils calls to_str, which is undefined on Ruby 1.8.7 and below
          def to_str
            path
          end unless respond_to? :to_str
        end
        f
      end
      $stdin = fin
      $stdout = fout
      yield
    ensure
      $stdin = STDIN
      $stdout = STDOUT
      FileUtils.rm_f [fin, fout]
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

    def dotfile path
      File.join dir, ".#{File.basename path}"
    end

    # Creates source file in HAUS_PATH/etc/* and returns [src, dotfile(src)]
    #
    # Installs Kernel#at_exit hook for cleaning up sources and dotfiles
    def hausfile type = :file
      mkdir_p etc

      pair = Dir.chdir etc do
        case type
        when :file
          f = str 8
          touch f
          [File.expand_path(f), dotfile(f)]
        when :dir
          d = str 8
          f = File.join d, str(8)
          mkdir d
          touch f
          [File.expand_path(d), dotfile(d)]
        when :link
          f = str 8
          ln_s Dir['/etc/*'][n], f
          [File.expand_path(f), dotfile(f)]
        else raise ArgumentError
        end
      end

      (@hausfiles ||= []).concat pair

      unless @exit_hook_installed
        pid = $$
        at_exit { clean if $$ == pid }
        @exit_hook_installed = true
      end

      pair
    end

    def clean
      rm_rf @hausfiles, :secure => true
      rm_rf haus, :secure => true
      @haus, @hausfiles = nil, nil
    end
  end
end
