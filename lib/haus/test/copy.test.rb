# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../../..', __FILE__)

require 'fileutils'
require 'haus/copy'
require 'haus/test/helper/dotfile_spec'

class Haus::CopySpec < DotfileSpec
  before do
    create_task Haus::Copy
  end

  after do
    remove_task_archive
  end

  describe :enqueue do
    it 'must add copy jobs to the queue' do
      must_add_task_jobs_to_queue :copies
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

    it 'must copy all sources as dotfiles' do
      must_result_in_dotfiles do |jobs|
        sf, df = jobs[:file]
        FileUtils.cmp(sf, df).must_equal true

        sd, dd = jobs[:dir]
        Dir[sd + '/*'].zip(Dir[dd + '/*']).each do |s,d|
          FileUtils.cmp(s,d).must_equal true
        end

        sl, dl = jobs[:link]
        FileUtils.cmp(File.readlink(sl), File.readlink(dl)).must_equal true
      end
    end
  end
end
