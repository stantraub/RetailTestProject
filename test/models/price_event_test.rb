require "test_helper"

class PriceEventTest < ActiveSupport::TestCase
  test "requires a positive price and an event_time" do
    event = price_events(:one)
    assert event.valid?

    [{ price: nil }, { price: 0 }, { event_time: nil }].each do |change|
      assert_not price_events(:one).tap { |e| e.assign_attributes(change) }.valid?, "expected #{change} to be invalid"
    end
  end

  test "can exist without any inventory event for the same product and store" do
    product, store = products(:two), stores(:two)
    assert_empty InventoryEvent.where(product: product, store: store)

    assert PriceEvent.create!(product: product, store: store, price: 4.50, event_time: Time.current).persisted?
  end

  test "latest_per_store and latest_per_product return only the newest price" do
    product, store = products(:two), stores(:two)
    PriceEvent.create!(product: product, store: store, price: 5.00, event_time: Time.utc(2026, 1, 1))
    newest = PriceEvent.create!(product: product, store: store, price: 6.00, event_time: Time.utc(2026, 2, 1))

    assert_equal [newest], product.price_events.latest_per_store.to_a
    assert_equal [newest], store.price_events.latest_per_product.to_a
  end

  test "the latest prices are listed newest first" do
    product, store = products(:two), stores(:two)
    other_product, other_store = products(:one), stores(:one)
    middle = PriceEvent.create!(product: product, store: store, price: 5.00, event_time: Time.utc(2026, 3, 1))
    newest = PriceEvent.create!(product: product, store: other_store, price: 6.00, event_time: Time.utc(2026, 5, 1))
    oldest = PriceEvent.create!(product: other_product, store: store, price: 7.00, event_time: Time.utc(2026, 2, 1))

    assert_equal [newest, middle], product.price_events.latest_per_store.to_a
    assert_equal [middle, oldest], store.price_events.latest_per_product.to_a
  end
end
