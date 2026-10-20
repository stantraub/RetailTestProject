require "test_helper"

class BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = brands(:one)
  end

  test "index lists brands with their product and alert counts" do
    add_alerts(2)

    get brands_url

    assert_response :success
    assert_select "td a", text: @brand.name
    assert_select "td.num", text: (@brand.products.count).to_s
    assert_select "td.num a[href=?]", alerts_path(brand_id: @brand.id), text: "2"
  end

  # One alert per day, each for its own product and store, so loading them one
  # row at a time would show up as extra queries (the query cache hides repeats).
  def add_alerts(count, start: 0)
    count.times.map do |i|
      n = start + i
      product = Product.create!(name: "Alert product #{n}", brand: @brand)
      store = Store.create!(address: "#{n} Alert Street")
      event = InventoryEvent.create!(store: store, product: product, inventory_present: false,
                                     event_time: Time.utc(2026, 1, 1) + n.days)
      Alert.create!(brand: @brand, store: store, product: product, inventory_event: event,
                    triggered_at: event.event_time)
    end
  end

  test "show lists the brand's recent alerts, newest first" do
    alerts = add_alerts(2)

    get brand_url(@brand)

    assert_select "h2", "Recent alerts"
    assert_select "td a[href=?]", alert_path(alerts.last), text: "2026-01-02 00:00"
    assert_select "td a", text: "1 Alert Street"
    assert_select "td .badge-no", text: "Out of stock, 2 checks", count: 2
    assert_select "p.empty", count: 0
  end

  test "show says when the brand has no alerts" do
    get brand_url(@brand)

    assert_select "p.empty", "No alerts for this brand."
    assert_select ".card-head a.btn", count: 0
  end

  test "show caps the alerts and links to all of them" do
    add_alerts(BrandsController::RECENT_ALERTS + 1)

    get brand_url(@brand)

    assert_select "td .badge-no", BrandsController::RECENT_ALERTS
    assert_select ".card-head a.btn[href=?]", alerts_path(brand_id: @brand.id), text: "View all 11 alerts"
  end

  test "show runs the same number of queries however many alerts there are" do
    add_alerts(2)
    with_two = count_queries { get brand_url(@brand) }
    add_alerts(8, start: 2)

    assert_equal with_two, count_queries { get brand_url(@brand) }
  end

  test "show lists the brand's products" do
    get brand_url(@brand)

    assert_response :success
    @brand.products.each { |product| assert_select "td a", text: product.name }
  end

  test "index runs the same number of queries however many brands there are" do
    before = count_queries { get brands_url }
    5.times { |i| Product.create!(name: "Extra #{i}", brand: Brand.create!(name: "Extra Brand #{i}")) }

    assert_equal before, count_queries { get brands_url }
  end
end
