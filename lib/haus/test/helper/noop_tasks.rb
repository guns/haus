# -*- encoding: utf-8 -*-

require 'haus/task'

class Haus
  class Noop < Task; end
  class Noop2 < Task; end

  class NoopTrue < Task
    def run
      true
    end
  end

  class NoopFalse < Task
    def run
      false
    end
  end
end
