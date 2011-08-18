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
      suffix = src.sub(%r{\A#{prefix}/?}, '').split('/').map { |d| d.sub /\A%/, '' }.join '/'
      "#{dir}/.#{suffix}"
    end

    # Returns user dotfiles as absolute paths
    def dotfiles
      Dir[File.expand_path "#{dir}/.*"].reject { |f| File.basename(f) =~ /\A\.{1,2}\z/ }
    end
  end
end
