# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Noop < Task; end
  class Noop2 < Task; end

  class NoopSelf < Task
    def call args = []
      self
    end
  end
end
