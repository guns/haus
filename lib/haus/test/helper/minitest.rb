# -*- encoding: utf-8 -*-

require 'fileutils'
require 'minitest/unit'

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
        f = File.open "/tmp/haus-filetty-#{rand 2**16}-#{n}", 'w+'
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
