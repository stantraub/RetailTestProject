require "test_helper"

class DetectAlertsJobTest < ActiveJob::TestCase
  setup do
    InventoryEvent.delete_all
    [1, 2].each do |day|
      InventoryEvent.create!(store: stores(:one), product: products(:one), inventory_present: false,
                             event_time: Time.utc(2026, 1, day))
    end
  end

  test "perform creates alerts using the configured streak length" do
    assert_difference -> { Alert.count }, 1 do
      DetectAlertsJob.perform_now
    end
  end

  test "running twice creates no duplicates" do
    DetectAlertsJob.perform_now
    assert_no_difference -> { Alert.count } do
      DetectAlertsJob.perform_now
    end
  end

  test "perform_later puts it on the default queue" do
    assert_enqueued_with(job: DetectAlertsJob, queue: "default") do
      DetectAlertsJob.perform_later
    end
  end
end
