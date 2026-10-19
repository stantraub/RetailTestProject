require "test_helper"

class BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = brands(:one)
  end

  test "index lists brands with their product counts" do
    get brands_url

    assert_response :success
    assert_select "td a", text: @brand.name
    assert_select "td.num", text: @brand.products.count.to_s
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
