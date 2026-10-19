require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    InventoryEvent.delete_all
    @product = products(:one)
  end

  # One event per store, so loading stores one row at a time would show up as
  # extra queries.
  def add_events(count)
    count.times.map do |i|
      store = Store.create!(address: "#{i} Test Street")
      InventoryEvent.create!(store: store, product: @product, inventory_present: i.even?,
                             event_time: Time.utc(2026, 1, 1) + i.days)
    end
  end

  test "index lists products with their brand and event counts" do
    add_events(2)

    get products_url

    assert_response :success
    assert_select "td a", text: @product.name
    assert_select "td a", text: @product.brand.name
    assert_select "td.num", text: "2"
  end

  test "show lists latest prices and the events newest first, with the store" do
    newest = add_events(3).last

    get product_url(@product)

    assert_response :success
    assert_select "td.num", text: "$9.99"
    assert_select "tbody tr td.nowrap", text: "2026-01-03 00:00"
    assert_select "td", text: newest.store.address
  end

  test "show runs the same number of queries however many events there are" do
    add_events(2)
    with_two = count_queries { get product_url(@product) }
    add_events(20)

    assert_equal with_two, count_queries { get product_url(@product) }
  end

  test "index runs the same number of queries however many products there are" do
    before = count_queries { get products_url }
    5.times { |i| Product.create!(name: "Extra #{i}", brand: Brand.create!(name: "Extra Brand #{i}")) }

    assert_equal before, count_queries { get products_url }
  end
end
