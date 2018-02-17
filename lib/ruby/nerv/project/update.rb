# -*- encoding: utf-8 -*-

require 'haus/logger'

module NERV; end
module NERV::Project; end

class NERV::Project::Update
  class << self
    def helptags
      system 'vim', '-c', 'silent! call pathogen#helptags() | quit'
    end
  end

  include Haus::Loggable

  attr_accessor :subprojects, :threads, :fetch

  def initialize proj, opts = {}
    @threads, @fetch = opts[:threads] || 1, opts[:fetch]

    @subprojects = if (filters = opts[:filter]) and not filters.empty?
      [filters].flatten.map do |str|
        if proj.keys.include? str
          proj[str]
        else
          proj.values.flatten.select { |p| p.base =~ Regexp.new(str, 'i') }
        end
      end
    else
      proj.values
    end.flatten.uniq.shuffle
  end

  def call
    idx, pool, lock, exceptions = -1, [], Mutex.new, []

    color = (17..231).to_a.shuffle.take(threads).map { |n| "x#{n}".to_sym }
    size  = subprojects.size
    label = "Thread %d [%#{size.to_s.length}d/#{size}]: "

    threads.times do |n|
      pool << Thread.new do
        loop do
          lock.synchronize { idx += 1 }
          proj = subprojects[idx]
          break if proj.nil? or not exceptions.empty?

          # Subproject#call is not thread-safe since it changes the CWD, so
          # we fork and wait instead.
          logger.io.print fmt([label % [n+1, idx+1], color[n]])
          Process.wait fork { proj.fetch = fetch; proj.update }

          if not $?.exitstatus.zero?
            # Let the other threads finish their current iteration
            exceptions << "Subproject update #{proj.base} did not exit cleanly!"
            break
          end
        end
      end
    end

    pool.each &:join
    log exceptions.map { |e| fmt [e, :red] }.join("\n") unless exceptions.empty?
    exceptions.empty?
  end
end
