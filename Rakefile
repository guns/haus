# -*- encoding: utf-8 -*-
#
# Copyright (c) 2009-2017 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

$:.unshift 'lib/ruby'

require 'shellwords'
require 'digest/sha1'
require 'nerv/project/update'
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
          system 'git checkout nerv >/dev/null 2>&1' or raise "#{name} checkout failed"
          if updated
            system 'git merge master >/dev/null 2>&1' or raise "#{name} merge failed"
          end
        end
      end
    }
  }
end

def vimdiffcmd a, b
  "edit #{b.shellescape} | diffthis | vsplit #{a.shellescape} | diffthis | tabnew"
end

task :env do
  require 'nerv/project/subproject' # Lazy load 'git' gem

  # Legacy non-interactive `merge` behavior
  ENV['GIT_MERGE_AUTOEDIT'] = 'no'

  @src = File.expand_path '/opt/src'
  @vim = File.expand_path '/opt/src/vimfiles'

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
        :base => "#{@src}/READONLY/git-imerge",
        :branch => %w[master],
        :files => { 'git-imerge' => 'bin/git-imerge' }
      },

      {
        :base => "#{@src}/git-remote-hg",
        :branch => %w[master guns],
        :files => { 'git-remote-hg' => 'bin/git-remote-hg' }
      },
    ],

    'completions' => [
      {
        :base   => "#{@src}/bash-completion",
        :branch => %w[master haus],
        :files  => lambda { |proj|
          src = "#{proj.base}/completions"
          dst = "#{proj.haus}/etc/_local/_share/bash-completion/completions"
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          { 'bash_completion' => 'etc/bashrc.d/bash_completion' }
        }
      },

      {
        :base   => "#{@src}/READONLY/git",
        :branch => %w[master],
        :files  => {
          'contrib/completion/git-completion.bash' => 'etc/bashrc.d/completions/git',
          'contrib/completion/git-prompt.sh' => 'etc/bashrc.d/git-prompt.sh',
          'contrib/diff-highlight/diff-highlight' => 'bin/diff-highlight',
        }
      },

      {
        :base   => "#{@src}/tmux",
        :branch => %w[nerv],
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
      { :base => "#{@vim}/diff_movement",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/fzf.vim",                 :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/gitv",                    :branch => %w[master haus], :files => :pathogen },
      { :base => "#{@vim}/gundo.vim",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/help_movement",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/httplog",                 :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/indenthaskell.vim",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/matchit.zip",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/nerdcommenter",           :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/nerdtree",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/NrrwRgn",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/pgsql.vim",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/python-syntax",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/rainbow_parentheses.vim", :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/refheap.vim",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/regbuf.vim",              :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/reporoot.vim",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/rust.vim",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/scratch.vim",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/screen.vim",              :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/Shebang",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/splitjoin.vim",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/tagbar",                  :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/timl",                    :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/ultisnips",               :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-abolish",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-bundler",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-coffee-script",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-commentary",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-dispatch",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-easy-align",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-elixir",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-emacsmodeline",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-eunuch",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-fireplace",           :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-fugitive",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-go",                  :branch => %w[master nerv], :files => :pathogen },
      { :base => "#{@vim}/vim-git",                 :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-haml",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-javascript",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-lsp",                 :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-markdown",            :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-monit",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-operator-user",       :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-orgmode",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-puppet",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-rails",               :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-rake",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-redl",                :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-repeat",              :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-rhubarb",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-rubocop",             :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-ruby-refactoring",    :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-scriptease",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-surround",            :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-terraform",           :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-toml",                :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-unimpaired",          :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/vim-varnish",             :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-table-mode",          :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/vim-visual-star-search",  :branch => %w[master],      :files => :pathogen },
      { :base => "#{@vim}/visualctrlg.vim",         :branch => %w[master guns], :files => :pathogen },
      { :base => "#{@vim}/zig.vim",                 :branch => %w[master],      :files => :pathogen },

      {
        :base   => "#{@src}/READONLY/fzf",
        :branch => %w[master],
        :files  => {
          'doc' => 'etc/vim/bundle/fzf/doc',
          'plugin' => 'etc/vim/bundle/fzf/plugin',
        },
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
        :base   => "#{@vim}/sparkup",
        :branch => %w[master nerv],
        :files  => lambda { |proj|
          src = "#{proj.base}/vim"
          dst = "#{proj.haus}/etc/vim/bundle/sparkup"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          { 'sparkup.py' => 'bin/sparkup' }
        }
      },

      {
        :base => "#{@src}/READONLY/nginx",
        :branch => %w[master],
        :files => lambda { |proj|
          src = "#{proj.base}/contrib/vim"
          dst = "#{proj.haus}/etc/vim/bundle/nginx"
          FileUtils.mkdir_p dst
          system *%W[rsync -a --delete --no-owner --no-group #{src}/ #{dst}/]
          nil
        }
      },

      {
        :base => "#{@src}/READONLY/mpv-image-viewer",
        :branch => %w[master],
        :files => {
          'scripts/image-positioning.lua' => 'etc/_config/mpv/scripts/image-positioning.lua',
        }
      },

      dr_chip_plugin('AnsiEsc'),
      dr_chip_plugin('DrawIt'),
      dr_chip_plugin('ManPageView')
    ],

    'dotfiles' => [
      {
        :base   => "#{@src}/urxvt-perls",
        :branch => %w[master nerv],
        :files  => 'etc/_urxvt/ext',
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
    require 'irb'
    IRB
  end.start
end

desc 'Update vim plugin helptags'
task :tags do
  NERV::Project::Update.helptags
end

desc 'Update subprojects (extra arguments are regexp filters)'
task :update => :env do
  opts = { :threads => (File.read('/proc/cpuinfo').scan(/^processor/i).size rescue 1) }
  opts[:threads] = ENV['JOBS'].to_i if ENV['JOBS']
  opts[:fetch  ] = ENV['FETCH'] == '1' if ENV['FETCH']
  opts[:filter ] = ARGV.drop_while { |a| a != 'update' }.drop 1

  if NERV::Project::Update.new(@subprojects, opts).call
    NERV::Project::Update.helptags
    NERV::Util::Notification.new(:preset => 'success', :message => 'Haus update complete.').call
  else
    NERV::Util::Notification.new(:preset => 'error', :message => 'Haus update failed.').call
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
    chown_R u, nil, 'etc/_config/_kupfer'
    chown_R u, nil, 'etc/_config/Thunar'
    chown_R u, 'docker', 'etc/_docker/'
    chown_R u, nil, 'etc/_local/_lib/clojure/guns'
    chown_R u, nil, 'etc/vim/UltiSnips'
  end
end

desc 'Change file mode of user files'
task :chmod do
  sh 'bin/fixperm', '--recursive', '--umask=022', 'etc/_config/htop'
end

desc 'Install udev hwdb rules to /etc/udev/hwdb.d/'
task :hwdb do
  dst = '/etc/udev/hwdb.d'
  if Dir.exist? dst
    cp_r Dir['share/udev/hwdb.d/*.hwdb'], dst
    sh 'systemd-hwdb', 'update'
    sh 'udevadm', 'trigger'
  else
    raise '%s is not a directory, or does not exist!' % dst
  end
end

desc 'Edit bash/readline directory bindings'
task :vimdirbindings do
  fs = %w[etc/bashrc.d/interactive.bash etc/inputrc]
  exec 'vim', '-O', *fs, '-c', 'windo execute "normal! /DIRECTORYBINDINGS$\<CR>zt"'
end

desc 'Edit bash/vim/readline edit shortcut bindings'
task :vimeditbindings do
  fs = %w[etc/bashrc.d/interactive.bash etc/vim/local/mappings.vim etc/inputrc]
  exec 'vim', '-O', *fs, '-c', 'windo execute "normal! /VIMEDITBINDINGS$\<CR>zt:set scrollbind\<CR>"'
end

desc 'Edit vim/readline git bindings'
task :vimgitbindings do
  fs = %w[etc/vim/local/mappings.vim etc/inputrc]
  exec 'vim', '-O', *fs, '-c', 'windo execute "normal! /VIMGITBINDINGS$\<CR>zt:set scrollbind\<CR>"'
end

desc 'Vimdiff iptables.script and ipset.conf'
task :vimdiffiptables do
  fs = ['/etc/iptables.script', 'share/iptables/iptables.script',
        '/etc/ipset.conf', 'share/ipset/ipset.conf']
  exec 'vim', *fs.each_slice(2).reduce([]) { |v, p| v << '-c' << vimdiffcmd(*p) }, '-c', 'tabclose | tabfirst'
end

namespace :opensearch do
  desc 'Remove XML files'
  task :clean do
    rm Dir['etc/_local/_share/_kupfer/searchplugins/*.xml']
  end

  desc 'Generate XML files'
  task :generate => :clean do
    require 'yaml'
    load 'bin/opensearch'

    o = Opensearch.new

    Dir.chdir 'etc/_local/_share/_kupfer/searchplugins' do
      YAML.load_file(File.expand_path 'search-engines.yml').each do |name, arg|
        url, method = arg
        puts '%s => %s (%s)' % [name, url, method || 'GET']
        File.open '%s.xml' % name, 'w' do |f|
          f.puts o.document(name, url, method || 'GET')
        end
      end
    end
  end
end
