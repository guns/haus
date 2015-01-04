# -*- encoding: utf-8 -*-
#
# Copyright (c) 2011 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

$:.unshift 'lib/ruby'

require 'shellwords'
require 'digest/sha1'
require 'nerv/project/update'
require 'nerv/project/subproject'
require 'nerv/util/notification'
require 'haus/logger'
require 'haus/queue'

include Haus::Loggable

def dr_chip_plugin name
  {
    :base   => "#{@vim}/DrChipVimPlugins/#{name}",
    :files  => :pathogen,
    :before => lambda { |proj|
      if proj.fetch
        begin
          system 'git checkout master >/dev/null 2>&1' or raise "#{name} checkout failed"
          updated = system "cd %s/.. && ./update #{name.shellescape} >/dev/null 2>&1" % proj.base.shellescape
          system 'git checkout guns >/dev/null 2>&1' or raise "#{name} checkout failed"
          if updated
            system 'git merge master >/dev/null 2>&1' or raise "#{name} merge failed"
          end
        end
      end
    }
  }
end

task :env do
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
        :branch => %w[stable],
        :files  => {
          'bin/lein'             => 'bin/lein',
          'doc/lein.1'           => 'share/man/man1/lein.1',
          'bash_completion.bash' => 'etc/bashrc.d/completions/lein'
        }
      },

      {
        :base   => "#{@src}/password-store",
        :branch => %w[master],
        :files  => {
          'src/password-store.sh'               => 'bin/pass',
          'man/pass.1'                          => 'share/man/man1/pass.1',
          'src/completion/pass.bash-completion' => 'etc/bashrc.d/completions/pass'
        }
      },

      {
        :base   => "#{@src}/jwzhacks",
        :before => lambda { |proj|
          if proj.fetch
            raise unless system 'git checkout master >/dev/null 2>&1'
            system './update.sh >/dev/null 2>&1'
            if not %x(git status --short).empty?
              proj.git.add
              proj.git.commit 'UPDATE'
            end
            raise unless system 'git checkout guns >/dev/null 2>&1'
            raise 'Merge failed' unless system 'git merge master >/dev/null 2>&1'
          end
          system 'git checkout guns >/dev/null 2>&1'
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
      },

      {
        :base => "#{@src}/git-remote-hg",
        :branch => %w[master guns],
        :files => { 'git-remote-hg' => 'bin/git-remote-hg' }
      },

      {
        :base => "#{@src}/READONLY/weechat-scripts",
        :branch => %w[master],
        :files => {
          'perl/buffers.pl'           => 'etc/%weechat/%perl/%autoload/buffers.pl',
          'perl/launcher.pl'          => 'etc/%weechat/%perl/%autoload/launcher.pl',
          'python/country.py'         => 'etc/%weechat/%python/%autoload/country.py',
          'python/go.py'              => 'etc/%weechat/%python/%autoload/go.py',
          'python/toggle_nicklist.py' => 'etc/%weechat/%python/%autoload/toggle_nicklist.py'
        }
      }
    ],

    'completions' => [
      {
        :base   => "#{@src}/bash-completion",
        :branch => %w[master haus],
        :files  => lambda { |proj|
          src = "#{proj.base}/completions"
          dst = "#{proj.haus}/etc/bashrc.d/bash_completion.d"
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          { 'bash_completion' => 'etc/bashrc.d/bash_completion' }
        }
      },

      {
        :base   => "#{@src}/READONLY/git",
        :branch => %w[master],
        :files  => {
          'contrib/completion/git-completion.bash' => 'etc/bashrc.d/completions/git',
          'contrib/completion/git-prompt.sh' => 'etc/bashrc.d/git-prompt.sh'
        }
      },

      {
        :base   => "#{@src}/tmux",
        :branch => %w[guns],
        :fetch  => :never,
        :files  => {
          'examples/tmux.vim' => 'etc/vim/bundle/tmux/syntax/tmux.vim',
          'examples/bash_completion_tmux.sh' => 'etc/bashrc.d/completions/tmux'
        }
      },

      {
        :base => "#{@src}/READONLY/ipset-bash-completion",
        :branch => %w[master],
        :files => {
          'ipset_bash_completion' => 'etc/bashrc.d/completions/ipset'
        }
      }
    ],

    'vimfiles' => [
      { :base => "#{@src}/jellyx.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@src}/vim-clojure-highlight",   :branch => %w[master],      :files => :pathogen },
      { :base => "#{@src}/vim-clojure-static",      :branch => %w[master],      :files => :pathogen },
      { :base => "#{@src}/vim-sexp",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@src}/vim-slamhound",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@src}/xterm-color-table.vim",   :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/ack.vim",                 :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/applescript.vim",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/BufOnly.vim",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/camelcasemotion",         :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/CountJump",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/delimitMate",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/devbox-dark-256",         :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/diff_movement",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/gitv",                    :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/gundo.vim",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/help_movement",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/httplog",                 :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/indenthaskell.vim",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/jellybeans.vim",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/jslint.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/lite-brite",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/matchit.zip",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/neomru.vim",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/nerdcommenter",           :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/nerdtree",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/NrrwRgn",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/rainbow_parentheses.vim", :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/refheap.vim",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/regbuf.vim",              :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/reporoot.vim",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/scratch.vim",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/screen.vim",              :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/Shebang",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/splitjoin.vim",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/tagbar",                  :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/timl",                    :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/tir_black",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/unite.vim",               :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/unite-argument",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/unite-git",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/unite-tag",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-abolish",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-bundler",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-coffee-script",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-commentary",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-easy-align",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-emacsmodeline",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-eunuch",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-fireplace",           :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-fugitive",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-git",                 :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-haml",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-javascript",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-markdown",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-monit",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-operator-user",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-orgmode",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-rails",               :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-rake",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-redl",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-repeat",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-scriptease",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-surround",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-unimpaired",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-varnish",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-visual-star-search",  :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/visualctrlg.vim",         :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/xoria256.vim",            :branch => %w[master],      :files => :pathogen },

      {
        :base   => "#{@src}/firefox-addons/vimperator-labs",
        :before => lambda { |proj|
          if proj.fetch
            system '{ git checkout master && git pull origin master; } >/dev/null 2>&1'
            raise 'vimperator git pull failed' if not $?.exitstatus.zero?
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
            system '{ cd %s && rake update && git add . && git commit -m UPDATE; } >/dev/null 2>&1' % proj.base.shellescape
          end
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
        :files  => :pathogen
      },

      {
        :base   => "#{@vim}/sparkup",
        :branch => %w[master guns],
        :files  => lambda { |proj|
          src = "#{proj.base}/vim"
          dst = "#{proj.haus}/etc/vim/bundle/sparkup"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          { 'sparkup.py' => 'bin/sparkup' }
        }
      },

      {
        :base   => "#{@src}/READONLY/go",
        :branch => %w[master],
        :files => lambda { |proj|
          src = "#{proj.base}/misc/vim"
          dst = "#{proj.haus}/etc/vim/bundle/go"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          # Copy bash completion file
          { 'misc/bash/go' => 'etc/bashrc.d/completions/go' }
        }
      },

      {
        :base => "#{@src}/READONLY/rust",
        :branch => %w[master],
        :files => lambda { |proj|
          src = "#{proj.base}/src/etc/vim"
          dst = "#{proj.haus}/etc/vim/bundle/rust"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          nil
        }
      },

      {
        :base => "#{@src}/nginx",
        :branch => %w[master vim],
        :files => lambda { |proj|
          src = "#{proj.base}/contrib/vim"
          dst = "#{proj.haus}/etc/vim/bundle/nginx"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          nil
        }
      },

      dr_chip_plugin('AnsiEsc'),
      dr_chip_plugin('DrawIt'),
      dr_chip_plugin('ManPageView')
    ],

    'dotfiles' => [
      {
        :base   => "#{@src}/urxvt-perls",
        :branch => %w[master],
        :files  => 'etc/%urxvt/ext',
      }
    ]
  }.map { |k, ps| [k, ps.map { |p| NERV::Project::Subproject.new p }] }]
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
  NERV::Project::Update.helptags
end

desc 'Update subprojects (extra arguments are regexp filters)'
task :update => :env do
  opts = { :threads => 4 }
  opts[:threads] = ENV['JOBS'].to_i if ENV['JOBS']
  opts[:fetch  ] = ENV['FETCH'] == '1' if ENV['FETCH']
  opts[:filter ] = ARGV.drop_while { |a| a != 'update' }.drop 1

  if NERV::Project::Update.new(@subprojects, opts).call
    NERV::Project::Update.helptags
    NERV::Util::Notification.new(:message => 'Haus update complete.').call
  else
    NERV::Util::Notification.new(:message => 'Haus update failed.').call
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

desc 'Import all terminfo files'
task :tic do
  Dir['share/terminfo/*.terminfo'].each { |f| sh 'tic', f }
end

desc 'Create Java keystores for certs'
task :keystore do
  require 'shellwords'
  load 'bin/cert'

  Dir.chdir 'etc/certificates' do
    Dir['*.crt'].each do |crt|
      ks = '%s.ks' % crt.chomp(File.extname crt)
      puts "→ #{ks}"
      c = Cert.new :certfile => crt, :keystore => ks
      c.write_keystore c.certificates
    end
  end
end

desc 'Change ownership of user directories'
task :chown do
  if ENV.has_key? 'SUDO_USER'
    u = ENV['SUDO_USER']
    chown_R u, nil, 'etc/vim/UltiSnips'
    chown_R u, nil, 'etc/%local/%lib/clojure/guns'
  end
end

desc 'Install udev hwdb rules to /etc/udev/hwdb.d/'
task :hwdb do
  dst = '/etc/udev/hwdb.d'
  if Dir.exists? dst
    cp_r Dir['share/udev/hwdb.d/*.hwdb'], dst
    sh 'udevadm', 'hwdb', '--update'
  else
    raise '%s is not a directory, or does not exist!' % dst
  end
end
