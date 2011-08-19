# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'fileutils'
require 'haus/clean'
require 'haus/test/helper/dotfile_spec'

$user ||= Haus::TestUser[$$]

class Haus::CleanSpec < DotfileSpec
  before do
    create_task Haus::Clean
  end

  after do
    remove_task_archive
  end

  describe :options do
    it 'must provide a --all option' do
      must_provide_option :all, %w[-a --all], true
    end
  end

  describe :enqueue do
    it 'must add linked dotfiles to the queue' do
      must_add_task_jobs_to_queue :deletions do |task, jobs|
        jobs.each_value do |s,d|
          FileUtils.mkdir_p File.dirname(d)
          FileUtils.ln_s s, d
        end
      end
    end

    it 'must add dotfiles that share the same name when options.all' do
      must_add_task_jobs_to_queue :deletions do |task, jobs|
        @task.options.all = true
        jobs.each_value do |s,d|
          FileUtils.mkdir_p File.dirname(d)
          FileUtils.touch d
        end
      end
    end

    it 'should not blow up on syscall errors' do
      class CleanSpecError < RuntimeError; end

      # EACCES
      src, dst = $user.hausfile
      FileUtils.ln_s src, dst
      File.lchmod 0200, dst
      @task.options.path = $user.haus
      lambda { @task.enqueue; raise CleanSpecError }.must_raise CleanSpecError
      FileUtils.rm_f dst

      # ENOENT
      FileUtils.touch File.join($user.etc, 'moozoo')
      lambda { @task.enqueue; raise CleanSpecError }.must_raise CleanSpecError

      # ENOTDIR
      src, dst = $user.hausfile :hier
      FileUtils.rm_rf File.dirname(dst)
      FileUtils.ln_s src, File.dirname(dst)
      lambda { @task.enqueue; raise CleanSpecError }.must_raise CleanSpecError
    end
  end

  describe :run do
    it 'must pass options to queue before enqueueing files' do
      # TODO
      # must_pass_options_to_queue_before_enqueueing
    end

    it 'must pass options to queue before execution' do
      # TODO
      # must_pass_options_to_queue_before_execution
    end

    it 'must execute the queue' do
      # TODO
      # must_execute_the_queue
    end

    it 'must return true or nil' do
      # TODO
      # must_return_true_or_nil
    end

    it 'must clean all dotfiles' do
      # TODO
      # must_result_in_dotfiles do |jobs|
      # end
    end
  end
end
