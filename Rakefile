# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

$:.unshift 'lib' # {{{1

require 'task/update'
require 'task/subproject'
require 'haus/logger'

include Haus::Loggable

task :env do # {{{1
  @src = File.expand_path '~guns/src'
  @vim = File.expand_path '~guns/src/vimfiles'
  @subprojects = Hash[{
    'completions' => [
      {
        :base   => "#{@src}/bash-completion",
        :branch => %w[master guns],
        :files  => proc { |proj|
          Hash[proj.git.ls_files('completions').map(&:first).reject do |f|
            File.directory? File.join(proj.base, f) or File.basename(f) =~ /\A(\.|_|Makefile)/
          end.map do |f|
            [f, "etc/bash_completion.d/#{File.basename f}"]
          end].merge 'bash_completion' => 'etc/bash_completion'
        }
      },

      {
        :base   => "#{@src}/git",
        :branch => %w[master],
        :files  => { 'contrib/completion/git-completion.bash' => 'etc/bash_completion.d/git' }
      },

      {
        :base   => "#{@src}/tmux",
        :push   => 'github',
        :files  => {
          'examples/tmux.vim' => 'etc/vim/bundle/tmux/syntax/tmux.vim',
          'examples/bash_completion_tmux.sh' => 'etc/bash_completion.d/tmux'
        },
        :before => proc { |proj|
          Dir.chdir proj.base do
            system '{ git checkout guns && rake pull && git merge master; } &>/dev/null'
            raise 'Pull and merge failed' if not $?.exitstatus.zero?
          end if proj.fetch
        },
      },

      {
        :base   => "#{@src}/leiningen",
        :branch => %w[1.x],
        :files  => {
          'bin/lein'             => 'bin/lein',
          'bash_completion.bash' => 'etc/bash_completion.d/lein'
        }
      }
    ],

    'vimfiles' => [
      { :base => "#{@src}/jellyx.vim",             :branch => %w[master],      :files => :pathogen, :pull => 'github' },
      { :base => "#{@src}/xterm-color-table.vim",  :branch => %w[master],      :files => :pathogen, :pull => 'github' },
      { :base => "#{@vim}/ack.vim",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/Align",                  :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/AnsiEsc.vim",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/applescript.vim",        :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/BufOnly.vim",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/camelcasemotion",        :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/closetag.vim",           :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/ColorX",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/CountJump",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/delimitMate",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/devbox-dark-256",        :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/diff_movement",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/gitv",                   :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/gnupg",                  :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/gundo.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/help_movement",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/hexman.vim",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/httplog",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/jellybeans.vim",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/jslint.vim",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/ManPageView",                                        :files => :pathogen },
      { :base => "#{@vim}/matchit.zip",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/nerdcommenter",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/nerdtree",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/nginx.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/NrrwRgn",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/operator-camelize.vim",  :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/regbuf.vim",             :branch => %w[master guns], :files => :pathogen, :push => 'github' },
      { :base => "#{@vim}/reporoot.vim",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/scratch.vim",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/screen.vim",             :branch => %w[master guns], :files => :pathogen, :push => 'github' },
      { :base => "#{@vim}/Shebang",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/tagbar",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/tir_black",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-coffee-script",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-emacsmodeline",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-fugitive",           :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-git",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-haml",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-javascript",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-markdown",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-operator-user",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-orgmode",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-preview",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-rails",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-rake",               :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-repeat",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-ruby-block-conv",    :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-speeddating",        :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-surround",           :branch => %w[master guns], :files => :pathogen, :push => 'github' },
      { :base => "#{@vim}/vim-textobj-rubyblock",  :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-textobj-user",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-unimpaired",         :branch => %w[master guns], :files => :pathogen, :push => 'github' },
      { :base => "#{@vim}/visualctrlg.vim",        :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/xoria256.vim",           :branch => %w[master],      :files => :pathogen },

      {
        :base   => "#{@vim}/Command-T",
        :branch => %w[master guns],
        :push   => 'github',
        :files  => 'etc/vim/bundle/Command-T',
        :after  => proc { |proj| system '/opt/ruby/1.8/bin/rake commandt &>/dev/null' }
      },

      {
        :base   => "#{@vim}/VimClojure",
        :branch => %w[master guns],
        :push   => 'github',
        :files  => 'etc/vim/bundle/VimClojure',
        :after  => proc { |proj| system 'rake nailgun &>/dev/null' }
      },

      {
        :base   => "#{@vim}/slimv.vim",
        :branch => %w[master guns],
        :push   => 'github',
        :files  => {
          'doc/paredit.txt'    => 'etc/vim/bundle/slimv.vim/doc/paredit.txt',
          'plugin/paredit.vim' => 'etc/vim/bundle/slimv.vim/plugin/paredit.vim'
        }
      },

      {
        :base   => "#{@vim}/vim-pathogen",
        :branch => %w[master],
        :files  => { 'autoload/pathogen.vim' => 'etc/vim/autoload/pathogen.vim' }
      },

      {
        :base   => "#{@vim}/ultisnips",
        :branch => %w[master guns],
        :push   => 'github',
        :files  => proc { |proj|
          dst = File.join proj.haus, 'etc/vim/bundle/ultisnips'
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --exclude=.git --exclude=.gitignore --exclude=*.snippets #{proj.base}/ #{dst}/]
          nil # Return nil because the work is done
        }
      }
    ],

    'dotfiles' => [
      {
        :base   => "#{@src}/urxvt-perls",
        :branch => %w[master guns],
        :push   => 'github',
        :files  => 'etc/%urxvt/ext',
      }
    ]
  }.map { |k, ps| [k, ps.map { |p| Task::Subproject.new p }] }]
end


desc 'Start an IRB console within the rake environment' # {{{1
task :console do
  require 'irb'
  ARGV.clear
  IRB.start
end

desc 'Update subprojects (extra arguments are regexp filters)' # {{{1
task :update => :env do
  opts = { :threads => 4 }
  opts[:threads] = ENV['JOBS'].to_i if ENV['JOBS']
  opts[:fetch  ] = ENV['FETCH'] == '1' if ENV['FETCH']
  opts[:filter ] = ARGV.drop_while { |a| a != 'update' }.drop 1

  if Task::Update.new(@subprojects, opts).call
    Task::Update.helptags
  end

  exit # Stop processing tasks!
end

desc 'Show untracked vim bundles and vimfile projects' # {{{1
task :untracked => :env do
  tracked  = @subprojects['vimfiles'].map { |h| File.basename h.base }

  log ['Untracked bundles:', :italic, :bold]
  log Dir['etc/vim/bundle/*'].reject { |f| tracked.include? File.basename(f) }.join("\n")

  log ["\nUntracked projects:", :italic, :bold]
  log Dir["#{@vim}/*"].reject { |f| tracked.include? File.basename(f) }.join("\n")
end

desc 'Import all terminfo files in share/terminfo' # {{{1
task :tic do
  Dir['share/terminfo/*'].each { |f| sh 'tic', f }
end

desc 'Compile the Vim Command-T bundle' # {{{1
task :commandt do
  Dir.chdir 'etc/vim/bundle/Command-T/ruby/command-t' do
    sh File.join(RbConfig::CONFIG['bindir'], 'ruby'), 'extconf.rb'
    sh 'make'
  end
end

desc 'Compile the VimClojure nailgun client' # {{{1
task :nailgun do
  Dir.chdir 'etc/vim/bundle/VimClojure/vimclojure-nailgun-client' do
    sh 'make'
  end
end

desc 'Show subproject source remotes' # {{{1
task :remotes => :env do
  @subprojects.values.flatten.each do |proj|
    log proj.base
    proj.git.remotes.each do |r|
      type, color = case r.name
      when proj.pull then ['↓', :x41]
      when proj.push then ['↑', :x135]
      else                ['∅', :red]
      end
      log ['    %s %s → %s' % [type, r.name, r.url], color]
    end
  end
end
