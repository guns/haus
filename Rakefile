# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

$:.unshift 'lib'
require 'task/update'
require 'task/subproject'

src = File.expand_path '~guns/src'
vim = File.expand_path '~guns/src/vimfiles'

@subprojects = Hash[{
  'completions' => [
    {
      :base   => "#{src}/bash-completion",
      :branch => %w[master guns],
      :files  => proc { |proj|
        Hash[proj.git.ls_files('completions').map(&:first).reject do |f|
          File.directory? File.join(proj.base, f) or File.basename(f) =~ /\A(_|Makefile)/
        end.map do |f|
          [f, "etc/bash_completion.d/#{File.basename f}"]
        end].merge 'bash_completion' => 'etc/bash_completion'
      }
    },

    {
      :base   => "#{src}/git",
      :branch => %w[master],
      :files  => { 'contrib/completion/git-completion.bash' => 'etc/bash_completion.d/git-completion.bash' }
    }
  ],

  'vimfiles' => [
    { :base => "#{src}/jellyx.vim",             :branch => %w[master],      :files => :pathogen, :remote => 'github' },
    { :base => "#{src}/xterm-color-table.vim",  :branch => %w[master],      :files => :pathogen, :remote => 'github' },
    { :base => "#{vim}/ack.vim",                :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/Align",                  :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/AnsiEsc.vim",            :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/applescript.vim",        :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/BufOnly.vim",            :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/camelcasemotion",        :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/closetag.vim",           :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/ColorX",                 :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/CountJump",              :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/delimitMate",            :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/devbox-dark-256",        :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/diff_movement",          :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/gitv",                   :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/gnupg",                  :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/gundo.vim",              :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/help_movement",          :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/hexman.vim",             :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/httplog",                :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/jellybeans.vim",         :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/jslint.vim",             :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/matchit.zip",            :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/ManPageView",            :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/NrrwRgn",                :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/nerdcommenter",          :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/nerdtree",               :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/nginx.vim",              :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/operator-camelize.vim",  :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/regbuf.vim",             :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/reporoot.vim",           :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/screen.vim",             :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/scratch.vim",            :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/Shebang",                :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/tagbar",                 :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/tir_black",              :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-coffee-script",      :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-emacsmodeline",      :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-fugitive",           :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/vim-git",                :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-haml",               :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-javascript",         :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-markdown",           :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-operator-user",      :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-orgmode",            :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/vim-preview",            :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/vim-rails",              :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-rake",               :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/vim-repeat",             :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-ruby-block-conv",    :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/vim-speeddating",        :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/vim-surround",           :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/vim-textobj-rubyblock",  :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-textobj-user",       :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/vim-unimpaired",         :branch => %w[master guns], :files => :pathogen },
    { :base => "#{vim}/visualctrlg.vim",        :branch => %w[master],      :files => :pathogen },
    { :base => "#{vim}/xoria256.vim",           :branch => %w[master],      :files => :pathogen },

    {
      :base   => "#{vim}/Command-T",
      :branch => %w[master guns],
      :files  => 'etc/vim/bundle/Command-T',
      :after  => proc { system '/opt/ruby/1.8/bin/rake commandt &>/dev/null' }
    },

    {
      :base   => "#{vim}/vim-pathogen",
      :branch => %w[master],
      :files  => { 'autoload/pathogen.vim' => 'etc/vim/autoload/pathogen.vim' }
    },

    # FIXME: Do not sync snippets directory!
    # {
    #   :base   => "#{vim}/ultisnips",
    #   :branch => %w[master guns],
    #   :files  => proc {},
    # },

    {
      :base   => "#{src}/tmux",
      :files  => {
        'examples/tmux.vim' => 'etc/vim/bundle/tmux/syntax/tmux.vim',
        'examples/bash_completion_tmux.sh' => 'etc/bash_completion.d/bash_completion_tmux.sh'
      },
      :before => proc { |proj|
        Dir.chdir proj.base do
          system '{ git checkout guns && rake pull && git merge master; } &>/dev/null'
          raise 'Pull and merge failed' if not $?.exitstatus.zero?
        end
      }
    }
  ],

  'dotfiles' => [
    {
      :base   => "#{src}/urxvt-perls",
      :branch => %w[master guns],
      :files  => 'etc/urxvt'
    }
  ]
}.map { |k, ps| [k, ps.map { |p| Task::Subproject.new p }] }]


### TASKS ###

desc 'Start an IRB console within the rake environment'
task :console do
  require 'irb'
  ARGV.clear
  IRB.start
end

desc 'Update subprojects (extra arguments are regexp filters)'
task :update do
  opts = { :threads => 4 }
  opts[:threads] = ENV['JOBS'].to_i if ENV['JOBS']
  opts[:fetch  ] = ENV['FETCH'] == '1' if ENV['FETCH']
  opts[:filter ] = ARGV.drop_while { |a| a != 'update' }.drop 1

  if Task::Update.new(@subprojects, opts).call
    Task::Update.helptags
  end

  exit # Stop processing tasks!
end

desc 'Import all terminfo files in share/terminfo'
task :tic do
  Dir['share/terminfo/*'].each { |f| sh 'tic', f }
end

desc 'Compile the Vim Command-T bundle'
task :commandt do
  Dir.chdir 'etc/vim/bundle/Command-T/ruby/command-t' do
    sh File.join(RbConfig::CONFIG['bindir'], 'ruby'), 'extconf.rb'
    sh 'make'
  end
end
