# Copyright (c) 2010 Sung Pae <sung@metablu.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

require 'fileutils'

class Update
  class << self
    def git_open *args
      require 'git'
      Git.open *args
    end
  end

  class NervUpdater
    include FileUtils

    class SystemCommandError < StandardError; end

    attr_reader :base

    def initialize opts = {}, fetch = false
      @base  = opts[:base]
      @files = opts[:files]
      @dst   = nerv_path opts[:dst] if opts[:dst]
      @fetch = fetch
      @master, @local_branch = [opts[:update]].flatten
      @callback = {
        :before_update => opts[:before_update],
        :after_update  => opts[:after_update]
      }
    end

    def nerv_root
      @@nerv_root ||= File.expand_path File.dirname(__FILE__)
    end

    def nerv_path path = ''
      File.join nerv_root, path
    end

    def chdir_base
      Dir.chdir(@base) { yield }
    end

    def git
      @git ||= Update.git_open @base
    end

    def checkout branch
      f = File.stat @base
      git.checkout branch
    ensure
      chown_R f.uid, f.gid, @base
    end

    def system_command *args
      raise SystemCommandError unless system *args
    end

    def git_update
      if @master
        checkout @master
        if @fetch
          chdir_base do
            system_command *%W[git remote update]
            system_command *%W[git pull origin #{@master}]
          end
        end

        if @local_branch
          checkout @local_branch
          chdir_base { system_command *%W[git merge #{@master}] } if @fetch
        end
      end

      true
    rescue SystemCommandError
      return false
    end

    def update src, dst
      chdir_base do
        raise "#{src} does not exist!" unless File.exists? src
        return if File.directory? src # git is now tracking empty directories?

        unless File.exists? dst and cmp src, dst
          mkdir_p File.dirname(dst)
          cp src, dst
        end
      end
    end

    def update_map
      @files.each do |src, dst|
        update src, nerv_path(dst)
      end
    end

    def update_list
      @files.each do |src|
        update src, File.join(@dst, src)
      end
    end

    def sync_files dst, opts = {}
      nerv_dst = nerv_path dst
      mkdir_p nerv_dst
      rm_rf nerv_dst if opts[:clobber]

      chdir_base do
        system_command *%W[rsync -a --delete --no-owner --exclude=.* #{@base}/ #{nerv_dst}/]
      end
    end

    def pathogen_path
      "etc/vim/bundle/#{File.basename @base}"
    end

    def fire_callback name
      @callback[name].call self if @callback[name]
    end

    def update_files
      case @files
      when Hash      then update_map
      when Array     then update_list
      when Proc      then @files = chdir_base { @files.call } and update_files
      when :git      then @files = git.ls_files.keys and update_list
      when :pathogen then sync_files pathogen_path, :clobber => true
      else raise "No handler for @files as #{@files.class}"
      end
    end

    def validate
      raise "No privileges to write #{nerv_root.inspect}" unless File.writable? nerv_root
      raise "#{@base.inspect} does not exist" unless Dir.exists? @base
    end

    def call
      puts "### Updating from #{@base}"
      validate

      if git_update
        fire_callback :before_update
        update_files
        fire_callback :after_update
      end
    end
  end # NervUpdater

  class Queue
    class << self
      include FileUtils

      def project
        File.expand_path '~guns/src'
      end

      def vimdir
        File.expand_path '~guns/src/vimfiles'
      end

      def completions
        [
          {
            :base   => "#{project}/bash-completion",
            :update => %w[master guns],
            :files  => proc {
              Hash[Dir['completions/*'].reject do |f|
                File.directory? f or f[%r(.*/(_|Makefile))]
              end.map do |f|
                [f, 'etc/bash_completion.d/' + File.basename(f)]
              end].merge('bash_completion' => 'core/etc/bash_completion')
            }
          },

          {
            :base   => "#{project}/git",
            :update => %w[master],
            :files  => { 'contrib/completion/git-completion.bash' => 'etc/bash_completion.d/git-completion.bash' }
          }
        ]
      end # completions

      def vimfiles
        [
          { :base => "#{project}/jellyx.vim",            :update => %w[master],      :files => :pathogen },
          { :base => "#{project}/xterm-color-table.vim", :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/ack.vim",                :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/Align",                  :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/AnsiEsc.vim",            :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/applescript.vim",        :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/BufOnly.vim",            :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/camelcasemotion",        :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/closetag.vim",           :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/ColorX",                 :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/CountJump",              :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/delimitMate",            :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/devbox-dark-256",        :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/diff_movement",          :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/gitv",                   :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/gnupg",                  :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/gundo.vim",              :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/help_movement",          :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/hexman.vim",             :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/httplog",                :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/jellybeans.vim",         :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/jslint.vim",             :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/matchit.zip",            :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/ManPageView",            :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/NrrwRgn",                :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/nerdcommenter",          :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/nerdtree",               :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/nginx.vim",              :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/operator-camelize.vim",  :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/regbuf.vim",             :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/reporoot.vim",           :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/screen.vim",             :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/scratch.vim",            :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/Shebang",                :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/tagbar",                 :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/tir_black",              :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-coffee-script",      :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-emacsmodeline",      :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-fugitive",           :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/vim-git",                :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-haml",               :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-javascript",         :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-markdown",           :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-operator-user",      :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-orgmode",            :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/vim-preview",            :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/vim-rails",              :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-rake",               :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/vim-rdoc",               :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-repeat",             :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-ruby-block-conv",    :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/vim-speeddating",        :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/vim-surround",           :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/vim-textobj-rubyblock",  :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-textobj-user",       :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/vim-unimpaired",         :update => %w[master guns], :files => :pathogen },
          { :base => "#{vimdir}/visualctrlg.vim",        :update => %w[master],      :files => :pathogen },
          { :base => "#{vimdir}/xoria256.vim",           :update => %w[master],      :files => :pathogen },

          { # We don't want to remove any compiled bits
            :base   => "#{vimdir}/Command-T",
            :update => %w[master guns],
            :files  => :git,
            :dst    => 'etc/vim/bundle/Command-T',
            :after_update => proc { system *%w[/opt/ruby/1.8/bin/rake commandt] }
          },

          {
            :base   => "#{vimdir}/vim-pathogen",
            :update => %w[master],
            :files  => { 'autoload/pathogen.vim' => 'etc/vim/autoload/pathogen.vim' }
          },

          # FIXME: Do not sync snippets directory!
          # {
          #   :base   => "#{vimdir}/ultisnips",
          #   :update => %w[master guns],
          #   :files  => proc {},
          # },

          {
            :base   => "#{project}/tmux",
            :files  => { 'examples/tmux.vim' => 'etc/vim/bundle/tmux/syntax/tmux.vim' },
            :before_update => proc { |obj|
              # ensure the bundle directory exists
              mkdir_p obj.nerv_path('etc/vim/bundle/tmux')
            }
          }
        ]
      end # vimfiles

      def dotfiles
        [
          {
            :base   => "#{project}/urxvt-perls",
            :update => %w[master guns],
            :files  => :git,
            :dst    => 'etc/urxvt'
          }
        ]
      end # dotfiles

      def untracked type
        tracked = vimfiles.map { |h| File.basename h[:base] }
        case type
        when :projects then Dir[File.expand_path '~guns/src/vimfiles/*']
        when :bundles  then Dir['etc/vim/bundle/*']
        end.select { |f| not tracked.include? File.basename(f) }
      end # untracked

      def remotes
        (completions + vimfiles + dotfiles).map do |h|
          [h[:base], Update.git_open(h[:base]).remote.url]
        end
      end # remotes
    end # self
  end # Queue

  ### Update

  class << self
    def helptags
      system 'vim', '-c', 'silent! call pathogen#helptags() | quit'
    end
  end

  def initialize types, threads = 1, fetch = false
    @queue = [types].flatten.map do |type|
      case type
      when 'completions' then Queue.completions
      when 'vimfiles'    then Queue.vimfiles
      when 'dotfiles'    then Queue.dotfiles
      else
        (Queue.completions + Queue.vimfiles + Queue.dotfiles).select do |q|
          q[:base] =~ Regexp.new(type, 'i')
        end
      end
    end.flatten

    @threads, @fetch = threads, fetch
  end

  def call
    queue, pool, lock = @queue.dup, [], Mutex.new

    @threads.times do |n|
      pool << Thread.new do

        loop do
          job = lock.synchronize { queue.shift }
          break if job.nil?

          # NervUpdater#call is not thread-safe since it changes the CWD,
          # so we fork and wait instead
          print "Thread #{n+1}: "
          pid = fork { NervUpdater.new(job, @fetch).call }
          Process.wait pid
        end

      end
      sleep 0.1 # avoid deadlocks on launch
    end

    pool.each &:join
  end
end # Update


### Tasks

verbose false
task :default => 'update'

@update = (ENV['UPDATE'] == '1')
@jobs   = (ENV['JOBS'].to_i > 0) ? ENV['JOBS'].to_i : 8

desc 'Fire up a rake console'
task :console do
  require 'irb'
  ARGV.clear
  puts 'Loaded: ' + File.expand_path(__FILE__)
  IRB.start
end

desc 'Run update tasks (filter with arguments)'
task :update do
  tasks = ARGV.drop_while { |a| a != 'update' }.drop 1
  tasks = %w[completions vimfiles] if tasks.empty?
  Update.new(tasks, @jobs, @update).call
  Update.helptags
  exit # Stop processing ARGV!
end

desc 'Show all untracked vim directories'
task :untracked => ['untracked:bundles', 'untracked:projects']

namespace :untracked do
  desc 'Show untracked vim bundles'
  task :bundles do
    puts "Untracked bundles:\n#{Update::Queue.untracked(:bundles).join "\n"}"
  end

  desc 'Show untracked vim projects'
  task :projects do
    puts "Untracked projects:\n#{Update::Queue.untracked(:projects).join "\n"}"
  end
end

desc 'Import all terminfo files in share/term'
task :tic do
  Dir['share/terminfo/*'].each do |f|
    cmd = ['tic', f]
    puts cmd.join(' ')
    system *cmd
  end
end

desc 'Compile the Vim Command-T bundle'
task :commandt do
  Dir.chdir 'etc/vim/bundle/Command-T/ruby/command-t' do
    ruby = File.join RbConfig::CONFIG['bindir'], 'ruby'
    system ruby, 'extconf.rb'
    system 'make'
  end
end

desc 'Merge remote branches'
task :merge do
  system 'git remote update' and
  system 'git checkout guns' and
  system 'git merge arch/local' and
  system 'git push arch'
end

desc 'Show remotes'
task :remotes do
  fmt = $stdout.tty? ? "%s ->\n    \e[32m%s\e[0m" : "%s ->\n    %s"
  Update::Queue.remotes.each do |pair|
    puts fmt % pair
  end
end
