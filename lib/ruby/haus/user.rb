# -*- encoding: utf-8 -*-

require 'etc'

class Haus
  class User < Etc::Passwd
    # Argument can either be a username or UID
    def initialize user = ENV['USER'] || Etc.getlogin
      entry = case user
      when Integer then Etc.getpwuid user
      when String  then Etc.getpwnam user
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
      dir + '/.' + src.sub(%r{\A#{prefix}/?}, '').split('/').map { |d| d.sub /\A_/, '' }.join('/')
    end

    # Returns a string describing why the given path is not trusted, where
    # trust is defined as being owned by the user, or by root, and is
    # owner-writeable only.
    #
    # This is a narrow definition of trust, but expanding this is rather
    # complicated, and complexity is the enemy of security.
    #
    # Returns nil if the path _is_ trusted.
    #
    # FIXME: Check ACLs, the damn things. A file with mode 0400 can be made
    #        world writable via one of three slightly different ACL systems!
    def distrusts path
      stat = File.stat path # Not :lstat! The real McCoy

      # "User distrusts path because ..."
      if stat.uid != uid and not stat.uid.zero?
        '%s is not owned by %s or by root' % [path.inspect, name.inspect]
      elsif not (stat.mode & 0002).zero?
        '%s is world writable' % path.inspect
      elsif not (stat.mode & 0020).zero?
        '%s is group writable' % path.inspect
      else
        nil
      end
    end
  end
end
