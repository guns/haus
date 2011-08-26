# -*- encoding: utf-8 -*-

require 'etc'

class Haus
  class User < Struct::Passwd
    # Argument can either be a username or UID
    def initialize user = Etc.getlogin
      entry = case user
      when Fixnum then Etc.getpwuid user
      when String then Etc.getpwnam user
      else raise ArgumentError
      end
      entry.members.each { |m| send "#{m}=", entry.send(m) }
    end

    # Return path as a home dotfile
    def dot src
      File.join dir, ".#{File.basename src}"
    end

    # Return hierfile as a home dotfile
    def hier src, prefix
      dir + '/.' + src.sub(%r{\A#{prefix}/?}, '').split('/').map { |d| d.sub /\A%/, '' }.join('/')
    end

    # Returns true if path is owned by the user or by root and is writeable
    # only by the owner.
    #
    # This is a narrow definition of trust, but expanding this is rather
    # complicated, and complexity is the enemy of security.
    #
    # FIXME: Check ACLs, the damn things. A file with mode 0400 can be made
    #        world writable via one of three slightly different ACL systems!
    def trusts? path
      stat = File.stat path # Not :lstat! The real McCoy
      (stat.uid == uid or stat.uid.zero?) and (stat.mode & 0022).zero?
    end
  end
end
