#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
#
# Copyright (c) 2012 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

require 'optparse'
require 'ostruct'
require 'fileutils'
require 'shellwords'
require 'notmuch'

class NotmuchMutt
  attr_reader :options

  def initialize opts = {}
    @options = OpenStruct.new opts
    options.database ||= File.expand_path '~/Mail/Local'
    options.outdir ||= File.expand_path '~/.mutt/notmuch/results'
  end

  def parser
    @parser ||= OptionParser.new nil, 20 do |opt|
      opt.banner = <<-BANNER.gsub /^ +/, ''
        Reimplementation of notmuch-mutt from notmuch/contrib

        Usage: #{File.basename __FILE__} [options]

        Options:
      BANNER

      opt.on '-d', '--database PATH', '[DEFAULT: %s]' % options.database do |arg|
        options.database = File.expand_path arg
      end

      opt.on '-o', '--outdir PATH', '[DEFAULT: %s]' % options.outdir do |arg|
        options.outdir = File.expand_path arg
      end

      opt.on '-n', '--noop' do
        options.noop = true
      end

      opt.on '-v', '--verbose' do
        options.verbose = true
      end
    end
  end

  def database
    @database ||= Notmuch::Database.new options.database
  end

  def create_maildir! paths
    return if paths.empty?

    fopts = { :noop => options.noop, :verbose => options.verbose }

    %w[cur new tmp].each do |dir|
      d = File.join options.outdir, dir
      FileUtils.rm_rf d, fopts
      FileUtils.mkdir_p d, fopts
    end

    paths.each do |src|
      unless File.exists? src
        src₁ = Dir['%s:*' % src[/(.*):/, 1].shellescape].first
        if src₁.nil?
          warn 'Unable to find %s' % src
          next
        end
        src = src₁
      end
      next unless path = src[%r{.*/((cur|new|tmp)/.*)}, 1]
      FileUtils.ln_s src, File.join(options.outdir, path), fopts
    end

    puts '%s search result%s' % [paths.size, ('s' unless paths.size == 1)] if options.verbose
  end

  def search query_string
    database.query(query_string).search_messages.map &:filename
  end

  def get_query args = []
    if args.any?
      args.join ' '
    else
      $stderr.print 'query: '
      $stdin.gets "\n"
    end
  end

  def run arguments = []
    args = parser.parse arguments
    rest = args.drop 1

    case args.first
    when 'search'  then create_maildir! search(get_query rest)
    else abort parser.help
    end
  end
end

$0 = File.basename(__FILE__) and NotmuchMutt.new.run ARGV if $0 == __FILE__
