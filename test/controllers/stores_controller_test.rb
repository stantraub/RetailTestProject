require "test_helper"

class StoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    InventoryEvent.delete_all
    @store = stores(:one)
  end

  # One event per product, each product with its own brand, so loading products
  # or brands one row at a time would show up as extra queries.
  def add_events(count)
    count.times.map do |i|
      product = Product.create!(name: "Product #{i}", brand: Brand.create!(name: "Brand #{i}"))
      InventoryEvent.create!(store: @store, product: product, inventory_present: i.even?,
                             event_time: Time.utc(2026, 1, 1) + i.days)
    end
  end

  test "index lists stores with their event counts" do
    add_events(3)

    get stores_url

    assert_response :success
    assert_select "td a", text: @store.address
    assert_select "td.num", text: "3"
  end

  test "show lists latest prices and the events newest first, with product and brand" do
    newest = add_events(3).last

    get store_url(@store)

    assert_response :success
    assert_select "td.num", text: "$9.99"
    assert_select "tbody tr td.nowrap", text: "2026-01-03 00:00"
    assert_select "a", text: newest.product.name
    assert_select "td", text: newest.product.brand.name
  end

  test "show runs the same number of queries however many events there are" do
    add_events(2)
    with_two = count_queries { get store_url(@store) }
    add_events(20)

    assert_equal with_two, count_queries { get store_url(@store) }
  end

  test "index runs the same number of queries however many stores there are" do
    before = count_queries { get stores_url }
    5.times { |i| Store.create!(address: "#{i} Extra Street") }

    assert_equal before, count_queries { get stores_url }
  end
end
