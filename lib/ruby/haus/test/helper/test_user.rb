# -*- encoding: utf-8 -*-

require 'fileutils'

class Haus
  #
  # Each new TestUser instance creates a new Haus directory, so when possible,
  # create TestUsers like this:
  #
  #     user = Haus::TestUser[$$]
  #
  # Certain methods trigger filesystem modifications, which are then scheduled
  # to be removed via Kernel::at_exit.
  #
  class TestUser < Struct::Passwd
    include FileUtils

    class << self
      attr_reader :list

      def [] key
        @list      ||= {}
        @list[key] ||= self.new
      end
    end

    attr_reader :haus, :hausfiles, :garbage

    def initialize
      name = ENV['TEST_USER'] || 'test'

      if name == Etc.getlogin
        raise 'FAILURE: Using your user account for testing would be extremely stupid.'
      elsif name == 'root'
        raise 'FAILURE: Using the root account for testing would be extremely stupid'
      end

      entry = Etc.getpwnam name
      entry.members.each { |m| send "#{m}=", entry.send(m) }

      @haus = File.join dir, ".#{randstr}"
      @hausfiles, @garbage = [], []

      abort "No privileges to write #{dir.inspect}" unless File.writable? dir
    rescue ArgumentError
      abort %Q{
        FAILURE: No such user #{name.inspect}
        FAILURE:
        FAILURE: This test suite requires a real Unix user account with a home
        FAILURE: directory writable by the current user. The name of the testing user
        FAILURE: is `test` by default, and can be changed by setting ENV['TEST_USER']
        FAILURE:
        FAILURE: All the files in the test user's home directory are at risk of being
        FAILURE: modified or destroyed.
      }.gsub(/^ +/, '')
    end

    def randstr len = 8
      chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
      'haus-' + (1..len).map { chars[rand chars.size] }.join
    end

    def etc
      File.join haus, 'etc'
    end

    def dot path
      File.join dir, ".#{File.basename path}"
    end

    # Creates source file in HAUS_PATH/etc/* and returns [src, dotfile(src)]
    #
    # Installs Kernel#at_exit hook for cleaning up sources and dotfiles
    def hausfile type = :file
      mkdir_p etc

      src_dst = Dir.chdir etc do
        case type
        when :file
          f = randstr
          touch f
          [File.expand_path(f), dot(f)]
        when :dir
          d = randstr
          f = File.join d, randstr
          mkdir d
          touch f
          [File.expand_path(d), dot(d)]
        when :hier
          d = '_' + randstr
          f = File.join d, randstr
          mkdir d
          touch f
          dst = File.join dir, d.sub(/\A_/, '.'), File.basename(f)
          garbage.push File.dirname(dst) # Explicitly remove parent
          [File.expand_path(f), dst]
        when :link
          f = randstr
          ln_s Dir['/etc/*'].select { |e| File.file? e and File.readable? e }.sort_by { rand }.first, f
          [File.expand_path(f), dot(f)]
        else raise ArgumentError
        end
      end

      @hausfiles.concat src_dst

      unless @exit_hook_installed
        pid = $$
        at_exit { clean if $$ == pid }
        @exit_hook_installed = true
      end

      src_dst
    end

    def clean
      rm_rf haus, :secure => true
      rm_rf hausfiles, :secure => true
      rm_rf garbage, :secure => true
      @haus = nil
      @hausfiles.clear
      @garbage.clear
    end
  end
end
