require "test_helper"

class AlertsControllerTest < ActionDispatch::IntegrationTest
  setup do
    InventoryEvent.delete_all
    @store   = stores(:one)
    @product = products(:one)

    @first_event  = create_event(day: 1, present: false)
    @second_event = create_event(day: 2, present: false)
    @alert        = create_alert(@second_event)
  end

  def create_event(day:, present:, store: @store, product: @product, month: 1)
    InventoryEvent.create!(store: store, product: product, inventory_present: present,
                           event_time: Time.utc(2026, month, day))
  end

  def create_alert(event)
    Alert.create!(brand: event.product.brand, store: event.store, product: event.product,
                  inventory_event: event, triggered_at: event.event_time)
  end

  test "index lists alerts with links to the brand, product and store" do
    get alerts_url

    assert_response :success
    assert_select "h1", "Alerts"
    assert_select "td a[href=?]", alert_path(@alert), text: "2026-01-02 00:00"
    assert_select "td a", text: @product.brand.name
    assert_select "td a", text: @product.name
    assert_select "td a", text: @store.address
    assert_select "td a", text: "View", count: 0
    assert_select "td .badge-no", text: "Out of stock, 2 checks"
    assert_select "tbody tr", 1
  end

  test "index lists the newest alerts first" do
    march = create_event(day: 1, present: false, month: 3)
    create_alert(march)

    get alerts_url

    assert_select "tbody tr:first-child td:first-child", "2026-03-01 00:00"
    assert_select "tbody tr:last-child td:first-child", "2026-01-02 00:00"
  end

  test "index can be filtered to one brand" do
    other_brand   = Brand.create!(name: "Other Brand")
    other_product = Product.create!(name: "Other Product", brand: other_brand)
    other_event   = create_event(day: 1, present: false, product: other_product)
    create_alert(other_event)

    get alerts_url(brand_id: other_brand.id)

    assert_response :success
    assert_select "h1", "Alerts for Other Brand"
    assert_select "tbody tr", 1
    assert_select "td a", text: "Other Product"
    assert_select "td a", text: @product.name, count: 0
  end

  test "index paginates and links between pages" do
    Pagy::OPTIONS[:limit].times do |i|
      create_alert(create_event(day: 1 + (i % 28), present: false, month: 2 + (i / 28)))
    end

    get alerts_url
    assert_select "tbody tr", Pagy::OPTIONS[:limit]
    assert_select "p", /Page 1 of 2/
    assert_select "a", text: "Next"
    assert_select "a", text: "Previous", count: 0

    get alerts_url(page: 2)
    assert_select "tbody tr", 1
    assert_select "p", /Page 2 of 2/
    assert_select "a", text: "Previous"
    assert_select "a", text: "Next", count: 0
  end

  test "a page past the end, even a huge number, redirects to the last page" do
    ["99", "99999999999999999999"].each do |page|
      get alerts_url(page: page)

      assert_redirected_to alerts_url(page: 1)
    end
  end

  test "pager links stay relative and keep the other query parameters" do
    Pagy::OPTIONS[:limit].times do |i|
      create_alert(create_event(day: 1 + (i % 28), present: false, month: 2 + (i / 28)))
    end

    get "/alerts?host=evil.example&controller=stores&brand_id=#{@product.brand.id}"

    assert_select "a", text: "Next" do |links|
      href = links.first["href"]
      assert href.start_with?("/alerts?"), "expected a relative /alerts link, got #{href}"
      assert_includes href, "brand_id=#{@product.brand.id}"
      assert_includes href, "page=2"
    end
  end

  test "show displays the alert and the two events that triggered it" do
    get alert_url(@alert)

    assert_response :success
    assert_select "a[href=?]", brand_path(@product.brand), text: @product.brand.name
    assert_select "a[href=?]", product_path(@product), text: @product.name
    assert_select "a[href=?]", store_path(@store), text: @store.address
    assert_select "tbody tr", 2
    assert_select "tbody tr:first-child td:first-child", "2026-01-01 00:00"
    assert_select "tbody tr:last-child td:first-child", "2026-01-02 00:00"
  end

  test "show lists every event of a longer streak" do
    third_event = create_event(day: 3, present: false)
    alert = Alert.create!(brand: @product.brand, store: @store, product: @product, inventory_event: third_event,
                          triggered_at: third_event.event_time, streak_length: 3)

    get alert_url(alert)

    assert_select "h1", "No inventory 3 times in a row"
    assert_select "tbody tr", 3
  end

end
