# -*- encoding: utf-8 -*-

require 'rubygems' # 1.8.6 compat
require 'minitest/pride' if $stdout.tty? and [].respond_to? :cycle
require 'minitest/autorun'
require 'haus/test/helper/test_user'

class DotfileSpec < MiniTest::Spec
  def create_task klass
    @task = klass.new
    @task.options.force = true
    @task.options.quiet = true
  end

  def remove_task_archive
    FileUtils.rm_f @task.queue.archive_path
  end

  def must_add_task_jobs_to_queue type
    user = Haus::TestUser[@task.class.to_s + '_enqueue']
    jobs = [:file, :dir, :link].inject({}) { |h,m| h.merge Hash[*user.hausfile(m)] } # Ruby 1.8.6

    @task.options.path = user.haus
    @task.options.users = [user.name]
    @task.enqueue
    @task.queue.send(type).map { |s,d| s }.sort.must_equal jobs.keys.sort
    @task.queue.targets.sort.must_equal jobs.values.sort
  end

  def must_pass_options_to_queue_before_enqueueing
    @task.instance_eval do
      def enqueue *args
        queue.options.cow.must_equal 'MOOCOW'
        super
      end
    end

    @task.options.cow = 'MOOCOW'
    @task.run
    @task.queue.options.cow.must_equal 'MOOCOW'
  end

  def must_pass_options_to_queue_before_execution
    @task.instance_eval do
      def execute *args
        queue.options.cow.must_equal 'MOOCOW'
        super
      end
    end

    @task.options.cow = 'MOOCOW'
    @task.run
    @task.queue.options.cow.must_equal 'MOOCOW'
  end

  def must_execute_the_queue
    @task.queue.executed?.must_equal nil
    @task.run
    @task.queue.executed?.must_equal true
  end

  def must_return_true_or_nil
    @task.options.quiet = true
    @task.options.force = true
    @task.run.must_equal true
    @task.options.force = false
    @task.run.must_equal nil
  end

  def must_result_in_dotfiles
    user = Haus::TestUser[@test.class.to_s + '_dotfiles']
    jobs = [:file, :dir, :link].inject({}) { |h,m| h.merge m => user.hausfile(m) } # Ruby 1.8.6 Hash[] does not like 2D arrays
    jobs.each_value { |s,d| File.exists?(d).must_equal false }

    @task.options.path = user.haus
    @task.options.users = [user.name]
    @task.run

    yield jobs
  end
end
