# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011-2017 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

require 'haus/logger'

module NERV; end
module NERV::CLI; end

# SGR colorized linear bar graph like:
#
#   CLI::Meter.new('Disk [%s] %s GB', [120, ':' => 540], 1000, :width => 60).to_s
#   => Disk [|||||::::::::::::::::::::::          66%] 660/1000 GB
#
class NERV::CLI::Meter
  include Haus::Loggable

  attr_accessor :format, :values, :max, :width, :precision, :summary_format

  # Params:
  #
  #   format:
  #     sprintf style format string. Must contain 2 placeholders:
  #       %s (graph), %s (value summary: "sum/max")
  #
  #   values:
  #     Array of values; can be specified in Haus::Logger#fmt format:
  #       [[30, :green], [25, :yellow]]
  #
  #     If a value is a Hash, the key is interpreted as the graph character:
  #       ['#' => [30, :green], ':' => [25, :yellow]]
  #
  #   max:
  #     Maximum value of graph.
  #
  # Options:
  #
  #   width:
  #     Width of graph; normally set to terminal width.
  #
  #   precision:
  #     Round the values in the summary to given precision, as in
  #     Float#round(precision); available only in Ruby 1.9+
  #
  #   summary_format:
  #     Format string for value summary; must contain two numeric
  #     placeholders.
  #       :summary_format => '%0.2f/%0.2f'
  #
  def initialize format, values, max, opts = {}
    @format         = format
    @values         = values
    @max            = max
    @width          = opts[:width] || terminal_width
    @precision      = opts[:precision] || 0
    @summary_format = opts[:summary_format] || '%d/%d'
  end

  def sum
    values.map do |v|
      v = v.values.first if v.is_a? Hash
      v.is_a?(Array) ? v[0] : v
    end.inject &:+
  end

  def graph
    # Graph length is space left over when sum == max
    length = width - (format % ['', summary_format % [max, max]]).length

    # Return empty string if there isn't enough space for a useful graph
    return '' if length < '100%'.length

    # Return blank string if max is 0, so we can avoid ZeroDivsionError
    return ' ' * length if max.zero?

    chars, styles = [], []

    values.each do |val|
      # Values may be Hashes, Arrays, and Numerics
      c, v, *s = val.is_a?(Hash) ? val.to_a.flatten : ['|', *val]

      # Multiplier (normalized)
      k = v.to_f / max
      k = 0 if k < 0
      k = 1 if k > 1

      count = (length * k).round

      chars.concat [c] * count
      styles.push  [count, s]
    end

    spaces = length - styles.map(&:first).inject(&:+)

    # Chop overflow
    until spaces >= 0
      chars.pop
      spaces += 1
    end

    # Char count should now equal graph length
    chars.concat [' '] * spaces
    styles.push  [spaces, [:black, :bold]]

    # Embed percentage
    pct = ((sum.to_f / max) * 100).round
    chars[-(pct.to_s.length+1)..-1] = (pct.to_s + '%').chars.to_a

    # Chunk, join, and colorize chars
    pos = 0
    styles.map do |count, style|
      buf  = chars[pos, count].join rescue (warn '%s[%d, %d] is nil!' % [chars, pos, count]; '')
      buf  = fmt [buf, *style] unless style.empty?
      pos += count
      buf
    end.join
  end

  def summary
    summary_format % [round(sum), round(max)]
  end

  def round n
    if Numeric.instance_method(:round).arity.zero?
      n.round
    else
      n.round precision
    end
  end

  def to_s
    format % [graph, summary]
  end

  def terminal_width
    return ENV['COLUMNS'].to_i if ENV['COLUMNS'] =~ /\A\d+\z/
    cols = %x(tput cols) rescue nil
    return cols.to_i if cols
    80
  end
end
