require "test_helper"

class AlertTest < ActiveSupport::TestCase
  setup do
    InventoryEvent.delete_all
    @store   = stores(:one)
    @product = products(:one)
  end

  def event(day, present, store: @store, product: @product, time: Time.utc(2026, 1, day))
    InventoryEvent.create!(store: store, product: product, inventory_present: present, event_time: time)
  end

  def alert_for(event, streak_length: 2)
    Alert.create!(brand: event.product.brand, store: event.store, product: event.product,
                  inventory_event: event, triggered_at: event.event_time, streak_length: streak_length)
  end

  test "an inventory event can trigger only one alert" do
    triggering = event(2, false)
    alert_for(triggering)

    assert_raises(ActiveRecord::RecordNotUnique) { alert_for(triggering) }
  end

  test "triggering_events are the streak's events, oldest first" do
    event(1, true)
    nos = [event(2, false), event(3, false), event(4, false)]

    assert_equal nos, alert_for(nos.last, streak_length: 3).triggering_events
  end

  test "triggering_events ignore other stores and products" do
    event(1, false, store: stores(:two))
    event(1, false, product: products(:two))
    triggering = event(2, false)

    assert_equal [triggering], alert_for(triggering).triggering_events
  end

  test "triggering_events order same-time events by id" do
    same_time = Time.utc(2026, 1, 1)
    earlier = event(1, false, time: same_time)
    later   = event(1, false, time: same_time)

    assert_equal [earlier, later], alert_for(later).triggering_events
  end
end
