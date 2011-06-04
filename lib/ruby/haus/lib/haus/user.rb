# -*- encoding: utf-8 -*-

require 'etc'

class Haus
  class User < Struct::Passwd
    # `user' can either be a username or UID
    def initialize user = Etc.getlogin
      entry = case user
      when Fixnum then Etc.getpwuid user
      when String then Etc.getpwnam user
      else raise ArgumentError
      end
      entry.members.each { |m| send "#{m}=", entry.send(m) }
    end
  end
end
