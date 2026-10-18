require "test_helper"
require "tempfile"

class PriceEvents::CsvImporterTest < ActiveSupport::TestCase
  setup do
    @store   = stores(:one)
    @product = products(:one) # fixture already has a 9.99 price on 2026-01-01
  end

  def import(*rows)
    file = Tempfile.new(["prices", ".csv"])
    file.write("Address,Product Name,Date,Price\n")
    rows.each { |address, product, date, price| file.write(%("#{address}","#{product}",#{date},#{price}\n)) }
    file.close
    PriceEvents::CsvImporter.new(file.path).call
  ensure
    file&.unlink
  end

  test "creates price events for new prices" do
    result = import([@store.address, @product.name, "2026-02-01", "10.50"])

    assert_equal 1, result.created
    assert_equal BigDecimal("10.50"), PriceEvent.order(:event_time).last.price
  end

  test "skips a price that matches the latest known price" do
    result = import(
      [@store.address, @product.name, "2026-02-01", "9.99"],
      [@store.address, @product.name, "2026-03-01", "12.00"]
    )

    assert_equal 1, result.created
    assert_equal 1, result.unchanged
  end

  test "skips unchanged prices within the file regardless of row order" do
    other = products(:two)
    result = import(
      [@store.address, other.name, "2026-03-01", "5.00"],
      [@store.address, other.name, "2026-02-01", "5.00"]
    )

    assert_equal 1, result.created
    assert_equal 1, result.unchanged
  end

  test "skips unknown stores and products, and invalid dates and prices" do
    result = import(
      ["No Such Store", @product.name, "2026-02-01", "1.00"],
      [@store.address, "No Such Product", "2026-02-01", "1.00"],
      [@store.address, @product.name, "not-a-date", "1.00"],
      [@store.address, @product.name, "2026-02-01", "abc"],
      [@store.address, @product.name, "2026-02-01", "-3"]
    )

    assert_equal 0, result.created
    assert_equal 2, result.unknown
    assert_equal 3, result.invalid
  end

  test "re-importing is a no-op even when a later price already exists" do
    rows = [
      [@store.address, @product.name, "2026-02-01", "10.00"],
      [@store.address, @product.name, "2026-02-15", "10.00"],
      [@store.address, @product.name, "2026-03-01", "11.00"]
    ]

    first  = import(*rows)
    second = import(*rows)

    assert_equal 2, first.created
    assert_equal 1, first.unchanged
    assert_equal 0, second.created
    assert_equal 3, second.unchanged
  end
end
