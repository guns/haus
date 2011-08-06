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

  class NoopNil < Task
    def run
      nil
    end
  end

  class NoopRaise < Task
    def run
      raise StandardError, 'NoopRaise'
    end
  end
end
