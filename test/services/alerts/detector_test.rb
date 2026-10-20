require "test_helper"

class Alerts::DetectorTest < ActiveSupport::TestCase
  setup do
    InventoryEvent.delete_all
    @store   = stores(:one)
    @product = products(:one)
  end

  # Records one event per status, one day apart, oldest first.
  # true = in stock, false = no inventory, nil = unknown.
  def record(statuses, store: @store, product: @product, start: Time.utc(2026, 1, 1))
    statuses.each_with_index.map do |present, day|
      InventoryEvent.create!(store: store, product: product, inventory_present: present, event_time: start + day.days)
    end
  end

  def detect(streak_length)
    Alerts::Detector.new(streak_length: streak_length).call
  end

  # N = 2 is the assignment's rule; N = 3 shows the length isn't hard-coded.
  [2, 3].each do |n|
    test "N=#{n}: alerts on the #{n}th no-inventory check in a row, not before" do
      record([false] * (n - 1))
      assert_equal 0, detect(n)

      last = record([false], start: Time.utc(2026, 2, 1)).last
      assert_equal 1, detect(n)

      alert = Alert.last
      assert_equal [last, n, @store, @product, @product.brand],
                   [alert.inventory_event, alert.streak_length, alert.store, alert.product, alert.brand]
    end

    test "N=#{n}: a longer run is still one alert" do
      record([false] * (n * 3))

      assert_equal 1, detect(n)
    end

    test "N=#{n}: a yes starts the count over" do
      record([false] * (n - 1) + [true] + [false] * n)

      assert_equal 1, detect(n)
    end
  end

  test "an unknown status breaks a streak" do
    record([false, nil, false])

    assert_equal 0, detect(2)
  end

  test "different stores and products do not combine" do
    record([false], store: stores(:one))
    record([false], store: stores(:two), start: Time.utc(2026, 1, 2))
    record([false], product: products(:two), start: Time.utc(2026, 1, 3))

    assert_equal 0, detect(2)
  end

  test "order is decided by event_time, not by insertion order" do
    # Inserted newest first, so ids run opposite to time:
    #   by id:   no (Jan 3), no (Jan 2), yes (Jan 1)  -> would alert on the Jan 2 event
    #   by time: yes (Jan 1), no (Jan 2), no (Jan 3)  -> alerts on the Jan 3 event
    jan3 = InventoryEvent.create!(store: @store, product: @product, inventory_present: false, event_time: Time.utc(2026, 1, 3))
    InventoryEvent.create!(store: @store, product: @product, inventory_present: false, event_time: Time.utc(2026, 1, 2))
    InventoryEvent.create!(store: @store, product: @product, inventory_present: true,  event_time: Time.utc(2026, 1, 1))

    assert_equal 1, detect(2)
    assert_equal jan3, Alert.last.inventory_event
  end

  test "re-running creates no duplicates but picks up new events" do
    record([false, false])
    assert_equal 1, detect(2)
    assert_equal 0, detect(2)

    record([true, false, false], start: Time.utc(2026, 2, 1))
    assert_equal 1, detect(2)
    assert_equal 2, Alert.count
  end

  test "the default comes from the app config, and invalid lengths are rejected" do
    assert_equal Rails.configuration.x.alerts.streak_length, Alerts::Detector.new.streak_length
    assert_raises(ArgumentError) { Alerts::Detector.new(streak_length: 0) }
    assert_raises(ArgumentError) { Alerts::Detector.new(streak_length: "abc") }
  end
end
