require "test_helper"
require "tempfile"

class InventoryEvents::CsvImporterTest < ActiveSupport::TestCase
  setup do
    InventoryEvent.delete_all
    @store   = stores(:one)
    @product = products(:one)
  end

  def import(rows)
    file = Tempfile.new(["inventory", ".csv"])
    file.write("Address,Product Name,Date,Inventory Present\n")
    rows.each { |address, product, date, present| file.write(%("#{address}","#{product}",#{date},#{present}\n)) }
    file.close
    InventoryEvents::CsvImporter.new(file.path).call
  ensure
    file&.unlink
  end

  test "imports rows, reading true-like values as in stock" do
    values = %w[True true TRUE t 1 False false no]
    result = import(values.each_with_index.map { |v, i| [@store.address, @product.name, "2025-03-#{i + 1}", v] })

    assert_equal values.size, result.created
    events = InventoryEvent.order(:event_time).to_a
    assert_equal [true] * 5 + [false] * 3, events.map(&:inventory_present)
    assert_equal [@store, @product, Time.utc(2025, 3, 1)], [events.first.store, events.first.product, events.first.event_time]
  end

  test "skips and counts rows with an unknown store or product, or a bad date" do
    result = import([["No Such Store", @product.name, "2025-03-04", "True"],
                     [@store.address, "No Such Product", "2025-03-04", "True"],
                     [@store.address, @product.name, "not-a-date", "True"]])

    assert_equal [0, 2, 1], [result.created, result.unknown, result.invalid]
    assert_equal 0, InventoryEvent.count
  end

  test "imports more rows than fit in one batch" do
    rows = Array.new(InventoryEvents::CsvImporter::BATCH_SIZE + 1) { [@store.address, @product.name, "2025-03-04", "True"] }

    assert_equal rows.size, import(rows).created
    assert_equal rows.size, InventoryEvent.count
  end
end
