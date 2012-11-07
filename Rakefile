# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

$:.unshift 'lib/ruby' # {{{1

require 'shellwords'
require 'digest/sha1'
require 'project/update'
require 'project/subproject'
require 'util/notification'
require 'haus/logger'

include Haus::Loggable

task :env do # {{{1
  # Legacy non-interactive `merge` behavior
  ENV['GIT_MERGE_AUTOEDIT'] = 'no'
  ENV['CURL_CA_BUNDLE'] = File.expand_path 'etc/certificates/haus-update.crt'
  ENV['GIT_SSL_CAINFO'] = ENV['CURL_CA_BUNDLE']

  @src = File.expand_path '~guns/src'
  @vim = File.expand_path '~guns/src/vimfiles'

  @subprojects = Hash[{
    'programs' => [
      {
        :base   => "#{@src}/leiningen",
        :branch => %w[preview],
        :files  => {
          'bin/lein'             => 'bin/lein',
          'doc/lein.1'           => 'share/man/man1/lein.1',
          'bash_completion.bash' => 'etc/bash_completion.d/lein'
        }
      },

      {
        :base   => "#{@src}/password-store",
        :branch => %w[master guns],
        :push   => 'github',
        :files  => {
          'src/password-store.sh'        => 'bin/pass',
          'man/pass.1'                   => 'share/man/man1/pass.1',
          'contrib/pass.bash-completion' => 'etc/bash_completion.d/pass'
        }
      },

      {
        :base   => "#{@src}/jwzhacks",
        :before => lambda { |proj|
          if proj.fetch
            system './update.sh &>/dev/null'
            if not %x(git status --short).empty?
              proj.git.add
              proj.git.commit 'UPDATE'
            end
          end
        },
        :files => { 'youtubedown' => 'bin/youtubedown' }
      }
    ],

    'completions' => [
      {
        :base   => "#{@src}/bash-completion",
        :branch => %w[master guns],
        :files  => lambda { |proj|
          Hash[proj.git.ls_files('completions').map(&:first).reject do |f|
            File.directory? File.join(proj.base, f) or File.basename(f) =~ /\A(\.|_|Makefile)/
          end.map do |f|
            [f, "etc/bash_completion.d/#{File.basename f}"]
          end].merge 'bash_completion' => 'etc/bash_completion'
        }
      },

      {
        :base   => "#{@src}/READONLY/git",
        :branch => %w[master],
        :files  => {
          'contrib/completion/git-completion.bash' => 'etc/bash_completion.d/git',
          'contrib/completion/git-prompt.sh' => 'etc/bashrc.d/git-prompt.sh'
        }
      },

      {
        :base   => "#{@src}/tmux",
        :branch => %w[master guns],
        :push   => 'github',
        :files  => {
          'examples/tmux.vim' => 'etc/vim/bundle/tmux/syntax/tmux.vim',
          'examples/bash_completion_tmux.sh' => 'etc/bash_completion.d/tmux'
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
      { :base => "#{@vim}/boxdraw",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/BufOnly.vim",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/camelcasemotion",        :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/CountJump",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/ctrlp.vim",              :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/delimitMate",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/devbox-dark-256",        :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/diff_movement",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/gitv",                   :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/gundo.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/help_movement",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/httplog",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/indenthaskell.vim",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/jellybeans.vim",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/jslint.vim",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/matchit.zip",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/nerdcommenter",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/nerdtree",               :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/nginx.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/NrrwRgn",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/operator-camelize.vim",  :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/refheap.vim",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/regbuf.vim",             :branch => %w[master guns], :files => :pathogen, :push => 'github' },
      { :base => "#{@vim}/reporoot.vim",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/scratch.vim",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/screen.vim",             :branch => %w[master guns], :files => :pathogen, :push => 'github' },
      { :base => "#{@vim}/Shebang",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/tagbar",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/tir_black",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-bundler",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-coffee-script",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-emacsmodeline",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-fugitive",           :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-git",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-haml",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-javascript",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-markdown",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-monit",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-operator-user",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-orgmode",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-rails",              :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-rake",               :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-repeat",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-ruby-block-conv",    :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-surround",           :branch => %w[master guns], :files => :pathogen, :push => 'github' },
      { :base => "#{@vim}/vim-textobj-rubyblock",  :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-textobj-user",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-unimpaired",         :branch => %w[master guns], :files => :pathogen, :push => 'github' },
      { :base => "#{@vim}/vim-varnish",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/visualctrlg.vim",        :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/xoria256.vim",           :branch => %w[master],      :files => :pathogen },

      {
        :base => "#{@src}/firefox/vimperator-labs",
        :before => lambda { |proj|
          if proj.fetch
            system '{ git checkout master && git-hg pull --rebase --force; } &>/dev/null'
            raise 'vimperator git-hg pull failed' if not $?.exitstatus.zero?
          end
        },
        :files => lambda { |proj|
          src = "#{proj.base}/vimperator/contrib/vim"
          dst = "#{proj.haus}/etc/vim/bundle/vimperator"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          nil # Work is done
        }
      },

      {
        :base => "#{@vim}/misc-vimscripts",
        :files => :pathogen,
        :before => lambda { |proj|
          if proj.fetch
            system '{ cd %s && rake update && git add . && git commit -m UPDATE; } &>/dev/null' % proj.base.shellescape
          end
        }
      },

      # {
      #   :base   => "#{@vim}/vimclojure",
      #   :push   => 'github',
      #   :before => lambda { |proj|
      #     # Update using git-hg bridge
      #     if proj.fetch
      #       system '{ git checkout master && git-hg pull --rebase --force && git checkout guns && git merge master; } &>/dev/null'
      #       raise 'vimclojure git-hg pull and merge failed' if not $?.exitstatus.zero?
      #     else
      #       system 'git checkout guns &>/dev/null' or raise 'vimclojure checkout failed'
      #     end
      #   },
      #   :files  => lambda { |proj|
      #     rm_rf ['vim/build', 'server/build'], :verbose => false
      #     system 'gradle vimZip &>/dev/null' or raise 'vimclojure zip build failure'
      #     system 'unzip -d vim/build/tmp %s &>/dev/null' % Dir['vim/build/**/*.zip'].first.shellescape
      #     raise 'vimclojure unzip failure' if not $?.exitstatus.zero?

      #     system 'rsync -a --delete --no-owner --no-group %s %s' % ["#{proj.base}/vim/build/tmp/".shellescape, "#{proj.haus}/etc/vim/bundle/vimclojure/"]
      #     raise 'vimclojure rsync failure' if not $?.exitstatus.zero?

      #     nil # The work is done
      #   }
      # },

      {
        :base   => "#{@vim}/paredit",
        :branch => %w[master guns],
        :pull   => 'hg',
        :push   => 'github',
        :files  => :pathogen,
        :before => lambda { |proj|
          if proj.fetch
            system '{ git checkout master && git-hg pull --rebase --force; } &>/dev/null'
            raise 'paredit git-hg pull failed' if not $?.exitstatus.zero?
          end
        }
      },

      {
        :base   => "#{@vim}/vim-pathogen",
        :branch => %w[master],
        :files  => { 'autoload/pathogen.vim' => 'etc/vim/autoload/pathogen.vim' }
      },

      {
        :base   => "#{@vim}/ManPageView",
        :files  => :pathogen,
        :before => lambda { |proj|
          if proj.fetch
            begin
              system 'git checkout master &>/dev/null' or raise 'ManPageView checkout failed'
              updated = system 'cd %s && rake update &>/dev/null' % proj.base.shellescape
              system 'git checkout guns &>/dev/null' or raise 'ManPageView checkout failed'
              if updated
                system 'git merge master &>/dev/null' or raise 'ManPageView merge failed'
              end
            ensure
              rm_f Dir['.Vimball*'], :verbose => false
            end
          end
        }
      },

      {
        :base   => "#{@vim}/ultisnips",
        :branch => %w[master guns],
        :push   => 'github',
        :files  => lambda { |proj|
          dst = File.join proj.haus, 'etc/vim/bundle/ultisnips'
          FileUtils.mkdir_p dst

          system *%W[rsync -a --delete --no-owner --no-group --exclude=/.git --exclude=/.gitignore --exclude=/UltiSnips #{proj.base}/ #{dst}/]
          system *%W[rsync -a --delete --no-owner --no-group #{proj.base}/UltiSnips/ #{dst}/UltiSnips/default/]
          snippets = Dir["#{proj.haus}/etc/vim/bundle/ultisnips/UltiSnips/*.snippets"]

          # Allow non-privileged user to edit snippets
          chown_R ENV['SUDO_USER'], nil, snippets, :verbose => false if ENV.has_key? 'SUDO_USER'

          nil # Return nil because the work is done
        }
      },

      {
        :base   => "#{@vim}/sparkup",
        :branch => %w[master guns],
        :files  => lambda { |proj|
          src = "#{proj.base}/vim"
          dst = "#{proj.haus}/etc/vim/bundle/sparkup"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          nil # Work is done
        }
      },

      {
        :base   => "#{@src}/READONLY/vidir",
        :branch => %w[master],
        :files  => { 'bin/vidir' => 'bin/vidir' },
        :before => lambda { |proj| FileUtils.chmod 0755, 'bin/vidir' }
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
  }.map { |k, ps| [k, ps.map { |p| Project::Subproject.new p }] }]
end


desc 'Start a Pry or IRB console within the rake environment' # {{{1
task :console => :env do
  ARGV.clear
  begin
    require 'pry'
    Pry
  rescue LoadError
    IRB
  end.start
end

desc 'Update vim plugin helptags'
task :tags do
  Project::Update.helptags
end

desc 'Update subprojects (extra arguments are regexp filters)' # {{{1
task :update => :env do
  opts = { :threads => 4 }
  opts[:threads] = ENV['JOBS'].to_i if ENV['JOBS']
  opts[:fetch  ] = ENV['FETCH'] == '1' if ENV['FETCH']
  opts[:filter ] = ARGV.drop_while { |a| a != 'update' }.drop 1

  if Project::Update.new(@subprojects, opts).call
    Project::Update.helptags
    Util::Notification.new(:message => 'Haus update complete.').call
  else
    Util::Notification.new(:message => 'Haus update failed.').call
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
