# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'haus/logger'
require 'haus/test/helper/minitest'
require 'haus/test/helper/noop_tasks'

class Haus
  class LoggerSpec < MiniTest::Spec
    describe :self do
      describe :italics? do
        # TODO
      end

      describe :colors256? do
        # TODO
      end
    end

    describe :SGR do
      it 'must be hash of Symbol keys' do
        Haus::Logger::SGR.keys.map { |k| k.class == Symbol }.all?.must_equal true
      end

      it 'must have string values consisting only [\d;]' do
        Haus::Logger::SGR.values.map { |v| v =~ /\A[\d;]+\z/ }.all?.must_equal true
      end

      it 'must return the key as String if the key is not a Symbol' do
        sgr = Haus::Logger::SGR
        sgr[0].must_equal '0'
        sgr[:reset].must_equal '0'
        sgr['reset'].must_equal 'reset'
      end
    end

    describe :initialize do
      it 'must set @io to $stdout by default' do
        Haus::Logger.new.io.must_equal $stdout
      end
    end

    describe :sgr do
      it 'must take at least one argument' do
        Haus::Logger.new.method(:sgr).arity.must_equal -2
      end

      it 'must return the msg itself if the io object is not a tty' do
        l = Haus::Logger.new File.open('/dev/null')
        l.sgr('bitbucket', :black).must_equal 'bitbucket'
      end

      it 'must surround the msg with given SGR codes' do
        with_filetty do
          l = Haus::Logger.new $stdout
          l.sgr('blue', :blue).must_equal "\e[34mblue\e[0m"
          buf = l.sgr('black on green and italic', :black, :GREEN, :italic)
          buf.must_equal "\e[30;42;3mblack on green and italic\e[0m"
        end
      end

      describe :fmt do
        it 'must take any number of arguments' do
          Haus::Logger.new.method(:fmt).arity.must_equal -1
        end

        it 'must join the arguments together' do
          l = Haus::Logger.new
          l.fmt('foo', 'bar', 'baz').must_equal 'foobarbaz'
        end

        it 'must SGR escape Array arguments and pass through others' do
          with_filetty do
            l = Haus::Logger.new
            l.fmt(['¡¡', :red], ' DANGER! ', ['!!', :red]).must_equal "\e[31m¡¡\e[0m DANGER! \e[31m!!\e[0m"
          end
        end
      end

      describe :log do
        it 'must take any number of arguments' do
          Haus::Logger.new.method(:log).arity.must_equal -1
        end

        it 'must write the arguments as a formatted line to the io device' do
          with_filetty do
            l = Haus::Logger.new
            l.log ['FOO', :magenta], ' BAR!'
            $stdout.rewind
            $stdout.read.must_equal "\e[35mFOO\e[0m BAR!\n"
          end
        end
      end
    end
  end

  class LoggableSpec < MiniTest::Spec
    before do
      class Haus::NoopApp
        include Haus::Loggable
      end
      @app = Haus::NoopApp.new
    end

    describe :log do
      it "must call the logger's :log method" do
        @app.instance_variable_set :@__haus_logger__, Class.new {
          def log *args
            @args = args
          end
        }.new

        @app.log 'foo', 'bar'
        @app.logger.instance_variable_get(:@args).must_equal %w[foo bar]
      end
    end

    describe :fmt do
      it "must call the logger's :fmt method" do
        @app.instance_variable_set :@__haus_logger__, Class.new {
          def fmt *args
            @args = args
          end
        }.new

        @app.fmt 'moo', 'car'
        @app.logger.instance_variable_get(:@args).must_equal %w[moo car]
      end
    end

    describe :logger do
      it 'must return the logger object' do
        @app.logger.must_equal @app.instance_variable_get(:@__haus_logger__)
      end

      it 'must create the logger object if it does not exist' do
        @app.instance_variable_get(:@__haus_logger__).must_be_nil
        @app.logger
        @app.instance_variable_get(:@__haus_logger__).must_be_kind_of Haus::Logger
      end
    end

    describe :__logger__ do
      it 'must be an alias to :logger' do
        # Method#== doesn't work for aliases in 1.8.6
        @app.__logger__.must_equal @app.logger
      end
    end
  end
end
