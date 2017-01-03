# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011-2017 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

require 'optparse'

module NERV; end
module NERV::CLI; end

# Instead of raising InvalidOption on unknown switches,
# SuperParser#superparse returns all unknown arguments, allowing it to act
# as a superset of another options set, which can be then parsed or passed
# separately.
class NERV::CLI::SuperParser < OptionParser
  attr_accessor :terminators

  def initialize *args
    @terminators ||= []
    super
  end

  def superparse arguments
    args, opts = arguments.clone, []

    loop do
      # Exit conditions
      if args.first == '--'
        args.shift
        break
      elsif terminators.include? args.first or args.empty?
        break
      end

      # Parse and search for an exact match
      switch, type, head, tail = case args.first
      when /\A--([^=]+)(.*)?/ then [search(:long,  $1), :long,  $1, $2]
      when /\A-([^-])(.*)?/   then [search(:short, $1), :short, $1, $2]
      else nil
      end

      case switch
      when Switch::NoArgument
        # Handle chained short options: `-abc` is `-a` + `-bc`
        if type == :short and not tail.empty?
          # Truncate args.first by head, not by shifting!
          args[0] = "-#{tail}"
          parse %W[-#{head}]
        else
          parse [args.shift]
        end
      when Switch
        # Option may or may not require an argument, but don't pass it the
        # next argument if it looks like an option
        if tail.empty? and args[1] !~ /\A-\S/
          parse args.shift(2)
        else
          parse [args.shift]
        end
      else
        # We don't know anything about this argument, so just skip over it
        opts.push args.shift
      end
    end

    # Soak up rest of arguments list
    opts.concat args
  end
end
