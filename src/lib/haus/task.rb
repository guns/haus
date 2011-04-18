# -*- encoding: utf-8 -*-

class Haus
  class Task
    class << self
      def list
        @@list ||= {}
      end

      def inherited base
        list[cmdstr base] = { :class => base }
      end

      def desc msg
        list[cmdstr self][:desc] = msg
      end

      private

      def cmdstr klass
        klass.to_s.downcase.split('::').last
      end
    end

    # Subclasses must define #options and #execute
    def call args = []
      execute options.parse(args)
    end
  end
end
