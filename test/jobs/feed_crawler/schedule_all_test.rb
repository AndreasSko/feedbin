require "test_helper"

module FeedCrawler
  class ScheduleAllTest < ActiveSupport::TestCase
    test "should enqueue FeedRefresher" do
      flush_redis
      assert_difference "Sidekiq::Queues['worker_slow_critical'].count", +2 do
        job = perform
        assert job.priority?
      end

      assert_not perform.priority?
    end

    private

    def perform
      ScheduleAll.new.tap do |job|
        def job.job_args(*args)
          [[1]]
        end
        job.perform
      end
    end
  end
end