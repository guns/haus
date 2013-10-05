# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

$:.unshift 'lib/ruby'

require 'shellwords'
require 'digest/sha1'
require 'project/update'
require 'project/subproject'
require 'util/notification'
require 'haus/logger'
require 'haus/queue'

include Haus::Loggable

task :env do
  # Legacy non-interactive `merge` behavior
  ENV['GIT_MERGE_AUTOEDIT'] = 'no'
  ENV['CURL_CA_BUNDLE'] = File.expand_path 'etc/certificates/haus-update.crt'
  ENV['GIT_SSL_CAINFO'] = ENV['CURL_CA_BUNDLE']

  @src = File.expand_path '~guns/src'
  @vim = File.expand_path '~guns/src/vimfiles'
  @emacs = File.expand_path '~guns/src/emacsfiles'

  @subprojects = Hash[{
    'programs' => [
      {
        :base   => "#{@src}/leiningen",
        :branch => %w[stable],
        :files  => {
          'bin/lein'             => 'bin/lein',
          'doc/lein.1'           => 'share/man/man1/lein.1',
          'bash_completion.bash' => 'etc/bash_completion.d/lein'
        }
      },

      {
        :base   => "#{@src}/password-store",
        :branch => %w[master guns],
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
            raise unless system 'git checkout master 2>&1 >/dev/null'
            system './update.sh 2>&1 >/dev/null'
            if not %x(git status --short).empty?
              proj.git.add
              proj.git.commit 'UPDATE'
            end
            raise unless system 'git checkout guns 2>&1 >/dev/null'
            raise 'Merge failed' unless system 'git merge master 2>&1 >/dev/null'
          end
          system 'git checkout guns 2>&1 >/dev/null'
        },
        :files => { 'youtubedown' => 'bin/youtubedown' }
      },

      {
        :base   => "#{@src}/READONLY/speedtest-cli",
        :branch => %w[master],
        :files  => { 'speedtest-cli' => 'bin/speedtest-cli' }
      },

      {
        :base   => "#{@src}/READONLY/git-cal",
        :branch => %w[master],
        :files  => { 'git-cal' => 'bin/git-cal' }
      },

      {
        :base => "#{@src}/READONLY/screenFetch",
        :branch => %w[master],
        :files => { 'screenfetch-dev' => 'bin/screenfetch' }
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
        :files  => {
          'examples/tmux.vim' => 'etc/vim/bundle/tmux/syntax/tmux.vim',
          'examples/bash_completion_tmux.sh' => 'etc/bash_completion.d/tmux'
        }
      },

      {
        :base   => "#{@src}/ponymix",
        :branch => %w[master guns],
        :files  => {
          'bash-completion' => 'etc/bash_completion.d/ponymix'
        }
      },

      {
        :base   => "#{@src}/systemd",
        :branch => %w[master guns],
        :files  => lambda { |proj|
          Hash[proj.git.ls_files('shell-completion/bash').map { |fs|
            f = fs.first
            [f, "etc/bash_completion.d/#{File.basename f}"]
          }]
        }
      }
    ],

    'vimfiles' => [
      { :base => "#{@src}/jellyx.vim",             :branch => %w[master],      :files => :pathogen, :pull => 'github' },
      { :base => "#{@src}/vim-clojure-static",     :branch => %w[master],      :files => :pathogen, :pull => 'github' },
      { :base => "#{@src}/vim-sexp",               :branch => %w[master],      :files => :pathogen, :pull => 'github' },
      { :base => "#{@src}/xterm-color-table.vim",  :branch => %w[master],      :files => :pathogen, :pull => 'github' },
      { :base => "#{@vim}/ack.vim",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/AnsiEsc.vim",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/applescript.vim",        :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/BufOnly.vim",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/camelcasemotion",        :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/CountJump",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/delimitMate",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/devbox-dark-256",        :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/diff_movement",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/gitv",                   :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/gundo.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/help_movement",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/httplog",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/indenthaskell.vim",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/jellybeans.vim",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/jslint.vim",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/lite-brite",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/matchit.zip",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/nerdcommenter",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/nerdtree",               :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/nginx.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/NrrwRgn",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/rainbow_parentheses.vim",:branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/refheap.vim",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/regbuf.vim",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/reporoot.vim",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/scratch.vim",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/screen.vim",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/Shebang",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/splitjoin.vim",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/tagbar",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/tir_black",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/unite.vim",              :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/unite-git",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/unite-tag",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-abolish",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-bundler",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-coffee-script",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-commentary",         :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-easy-align",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-emacsmodeline",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-eunuch",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-fireplace",          :branch => %w[master guns], :files => :pathogen },
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
      { :base => "#{@vim}/vim-redl",               :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-repeat",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-scriptease",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-surround",           :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-unimpaired",         :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-varnish",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-visual-star-search", :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/visualctrlg.vim",        :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/xoria256.vim",           :branch => %w[master],      :files => :pathogen },

      {
        :base   => "#{@src}/firefox/vimperator-labs",
        :before => lambda { |proj|
          if proj.fetch
            system '{ git checkout master && git-hg pull --rebase --force; } 2>&1 >/dev/null'
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
        :base   => "#{@vim}/misc-vimscripts",
        :files  => :pathogen,
        :before => lambda { |proj|
          if proj.fetch
            system '{ cd %s && rake update && git add . && git commit -m UPDATE; } 2>&1 >/dev/null' % proj.base.shellescape
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
              system 'git checkout master 2>&1 >/dev/null' or raise 'ManPageView checkout failed'
              updated = system 'cd %s && rake update 2>&1 >/dev/null' % proj.base.shellescape
              system 'git checkout guns 2>&1 >/dev/null' or raise 'ManPageView checkout failed'
              if updated
                system 'git merge master 2>&1 >/dev/null' or raise 'ManPageView merge failed'
              end
            ensure
              FileUtils.rm_f Dir['.Vimball*'], :verbose => false
            end
          end
        }
      },

      {
        :base   => "#{@vim}/ultisnips",
        :branch => %w[master guns],
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
        :base   => "#{@src}/READONLY/go",
        :before => lambda { |proj|
          if proj.fetch
            system '{ git checkout master && git-hg pull --rebase --force; } 2>&1 >/dev/null'
            raise 'go git-hg pull failed' unless $?.exitstatus.zero?
          end
        },
        :files => lambda { |proj|
          src = "#{proj.base}/misc/vim"
          dst = "#{proj.haus}/etc/vim/bundle/go"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          # Copy bash completion file
          { 'misc/bash/go' => 'etc/bash_completion.d/go' }
        }
      }
    ],

    'emacsfiles' => [
      {
        :base   => "#{@emacs}/evil",
        :branch => %w[master guns],
        :files  => 'etc/%emacs.d/evil'
      },

      {
        :base   => "#{@emacs}/paredit",
        :branch => %w[master],
        :files  => { 'paredit.el' => 'etc/%emacs.d/paredit/paredit.el' }
      }
    ],

    'dotfiles' => [
      {
        :base   => "#{@src}/urxvt-perls",
        :branch => %w[master],
        :files  => 'etc/%urxvt/ext',
      }
    ]
  }.map { |k, ps| [k, ps.map { |p| Project::Subproject.new p }] }]
end

desc 'Start a Pry or IRB console within the rake environment'
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

desc 'Update subprojects (extra arguments are regexp filters)'
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

desc 'Replace vim bundles with direct symlinks for development'
task :vimlink => :env do
  vs = @subprojects['vimfiles']
  xs = []

  ARGV.drop_while { |a| a != 'vimlink' }.drop(1).each do |pat|
    xs.concat vs.select { |p| p.base =~ Regexp.new(pat, 'i') }.map(&:base)
  end

  q = Haus::Queue.new

  xs.each do |src|
    q.add_link src, "etc/vim/bundle/#{File.basename src}"
  end

  q.execute

  exit # Stop processing tasks!
end

desc 'Show untracked vim bundles and vimfile projects'
task :untracked => :env do
  tracked  = @subprojects['vimfiles'].map { |h| File.basename h.base }

  log ['Untracked bundles:', :italic, :bold]
  log Dir['etc/vim/bundle/*'].reject { |f| tracked.include? File.basename(f) }.join("\n")

  log ["\nUntracked projects:", :italic, :bold]
  log Dir["#{@vim}/*"].reject { |f| tracked.include? File.basename(f) }.join("\n")
end

desc 'Show subproject source remotes'
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

desc 'Import all terminfo files in share/terminfo'
task :tic do
  Dir['share/terminfo/*'].each { |f| sh 'tic', f }
end

desc 'Install service files in lib/systemd to /usr/local/lib/systemd'
task :service do
  require 'erb'

  def path cmd
    %x(/bin/sh -c "command -v #{cmd.shellescape}").chomp
  end

  Dir['share/systemd/**/*.service.erb'].each do |service|
    dst = File.join '/usr/local/lib/systemd', service[%r{share/systemd/(.*)}, 1].chomp('.erb')
    puts dst
    File.open dst, 'w' do |f|
      f.puts ERB.new(File.read service).result(binding)
    end
  end
end

desc 'Update WeeChat scripts'
task :weechat do
  %w[
    http://www.weechat.org/files/scripts/buffers.pl
    http://www.weechat.org/files/scripts/launcher.pl
    http://www.weechat.org/files/scripts/country.py
    http://www.weechat.org/files/scripts/go.py
    http://www.weechat.org/files/scripts/shell.py
    http://www.weechat.org/files/scripts/toggle_nicklist.py
  ].each do |url|
    file = 'etc/%%weechat/%%%s/%%autoload/%s' % [
      { '.pl' => 'perl', '.py' => 'python' }[File.extname url],
      File.basename(url)
    ]
    sh 'curl', '-#L', '-o' + file, url
  end
end

desc 'Create Java keystores for certs'
task :keystore do
  require 'shellwords'
  require 'util/password'
  load 'bin/cert'

  Dir.chdir 'etc/certificates' do
    mkdir_p 'java'
    cmd = %q(/bin/bash -c 'keytool -importcert -trustcacerts -noprompt -keystore %s -file <(cat) -storepass:env STOREPASS -alias %s')

    Dir['*.crt'].each do |crt|
      cs = Cert.new.parse_certs File.read(crt)
      ks = 'java/%s.ks' % crt.chomp(File.extname crt)
      pw = Util::Password.password

      rm_f ks

      ENV['STOREPASS'] = pw

      cs.each_with_index do |c, i|
        IO.popen cmd % [ks, i], 'w' do |io|
          io.puts c.to_s
          io.close
        end
      end
    end
  end
end
