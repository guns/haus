# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Noop < Task; end
  class Noop2 < Task; end

  class NoopTrue < Task
    def call args = []
      true
    end
  end

  class NoopFalse < Task
    def call args = []
      false
    end
  end

  class NoopSelf < Task
    def call args = []
      self
    end
  end
end
