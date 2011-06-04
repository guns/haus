# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Link < Task
    desc 'Create dotfile symlinks'
    banner "Create dotfile symlinks from #{Options.new.path}/etc/*"

    def call args = []
    end
  end
end
