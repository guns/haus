# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'fileutils'
require 'haus/link'
require 'haus/test/helper/dotfile_spec'
require 'pathname'

class Haus::LinkSpec < DotfileSpec
  before do
    create_task Haus::Link
  end

  after do
    remove_task_archive
  end

  describe :options do
    it 'must provide an --absolute option' do
      must_provide_option :relative, %w[-a --absolute], false
    end
  end

  describe :enqueue do
    it 'must add link jobs to the queue' do
      must_add_task_jobs_to_queue :links
    end

    it 'must annotate files with untrusted sources' do
      must_annotate_files_with_untrusted_sources
    end
  end

  describe :run do
    it 'must pass options to queue before enqueueing files' do
      must_pass_options_to_queue_before_enqueueing
    end

    it 'must pass options to queue before execution' do
      must_pass_options_to_queue_before_execution
    end

    it 'must execute the queue' do
      must_execute_the_queue
    end

    it 'must return true or nil' do
      must_return_true_or_nil
    end

    it 'must link all sources as dotfiles' do
      must_result_in_dotfiles do |jobs|
        jobs.each_value do |src, dst|
          File.readlink(dst).must_equal Haus::Utils.relpath(src, dst)
        end
      end
    end
  end
end
