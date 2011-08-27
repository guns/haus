# -*- encoding: utf-8 -*-

require 'fileutils'
require 'pathname'
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

          # FileUtils calls to_str, which is undefined on Ruby 1.8.6
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

    def extant? file
      File.lstat(file) ? true : false
    rescue Errno::ENOENT
      false
    end

    def relpath source, destination
      # We don't need the destination leaf
      src, dst = [source, File.dirname(destination)].map do |file|
        base = nil

        # Find the deepest existing node (not :extant?; we are avoiding links)
        Pathname.new(file).ascend do |p|
          if p.exist?
            base = p
            break
          end
        end

        # Rebase if necessary
        Pathname.new base ? file.sub(/\A#{base}/, base.realpath.to_s) : file
      end

      src.relative_path_from(dst).to_s
    end
  end
end

# Just for fun
if defined? PrideIO and MiniTest::Unit.output.kind_of? PrideIO
  require 'haus/logger'

  if Haus::Logger.colors256?
    xterm_colors = 16.step(196, 36).inject [] do |ary, base|
      ary + (base..base+5).map do |n|
        6.times.map { |k| '38;5;%d' % (n + 6*k) }
      end
    end.shuffle.first
    MiniTest::Unit.output.instance_variable_set :@colors, xterm_colors
    MiniTest::Unit.output.instance_variable_set :@size,   xterm_colors.size
  end
end
