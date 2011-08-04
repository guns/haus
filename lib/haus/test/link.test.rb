# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'fileutils'
require 'haus/link'
require 'haus/test/helper/dotfile_spec'

class Haus::LinkSpec < DotfileSpec
  before do
    create_task Haus::Link
  end

  after do
    remove_task_archive
  end

  describe :options do
    it 'should provide a --relative option' do
      h = Haus::Link.new %w[--relative]
      h.run
      h.options.relative.must_equal true
    end
  end

  describe :enqueue do
    it 'should add link jobs to the queue' do
      add_task_jobs_to_queue :links
    end
  end

  describe :run do
    it 'should pass options to queue before enqueueing files' do
      pass_options_to_queue_before_enqueueing
    end

    it 'should pass options to queue before execution' do
      pass_options_to_queue_before_execution
    end

    it 'should execute the queue' do
      execute_the_queue
    end

    it 'should return true or nil' do
      return_true_or_nil
    end

    it 'should link all sources as dotfiles' do
      should_result_in_dotfiles do |jobs|
        jobs.each_value do |s,d|
          File.readlink(d).must_equal s
        end
      end
    end
  end
end
