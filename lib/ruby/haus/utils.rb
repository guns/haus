# -*- encoding: utf-8 -*-

require 'pathname'

class Haus; end

module Haus::Utils
  extend self

  # Returns the relative path between the `physical` (non-link-traversed)
  # paths of given files.
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
