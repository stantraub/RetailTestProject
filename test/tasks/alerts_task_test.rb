require "test_helper"
require "rake"

class AlertsTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("alerts:detect")
    InventoryEvent.delete_all
    [1, 2, 3].each do |day|
      InventoryEvent.create!(store: stores(:one), product: products(:one), inventory_present: false,
                             event_time: Time.utc(2026, 1, day))
    end
  end

  def run_task(*args)
    task = Rake::Task["alerts:detect"]
    task.reenable
    capture_io { task.invoke(*args) }.first
  end

  test "uses the default streak length" do
    assert_match "Created 1 alerts for 2 in a row", run_task
    assert_equal [2], Alert.pluck(:streak_length)
  end

  test "takes the streak length as an argument and rejects invalid ones" do
    assert_match "Created 1 alerts for 3 in a row", run_task("3")
    assert_equal [3], Alert.pluck(:streak_length)
    assert_raises(ArgumentError) { run_task("0") }
  end
end
