# -*- encoding: utf-8 -*-

require 'haus/options'
require 'haus/user'

class Haus
  #
  # Provides common options for all tasks
  #
  class TaskOptions < Options
    def users= ary
      users = ary.map { |a| User.new a }

      users.each do |u|
        if not File.directory? u.dir
          raise "#{u.name}'s home directory, #{u.dir.inspect}, does not exist"
        end
      end

      super users
    end
  end
end
