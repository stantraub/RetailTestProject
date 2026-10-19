require "csv"

module InventoryEvents
  # Imports inventory checks from a CSV with the columns:
  #   Address, Product Name, Date, Inventory Present
  #
  # Importing the same file twice inserts its events twice; clear events first
  # (re-running db:seed does this).
  class CsvImporter
    BATCH_SIZE = 5_000

    TRUE_VALUES = %w[true TRUE t T 1 True].freeze

    Result = Struct.new(:rows, :created, :unknown, :invalid, keyword_init: true)

    def initialize(path)
      @path = path
    end

    def call
      store_ids   = Store.pluck(:address, :id).to_h
      product_ids = Product.pluck(:name, :id).to_h
      times       = {} # the file has about 365 distinct dates; parse each once
      batch       = []
      result      = Result.new(rows: 0, created: 0, unknown: 0, invalid: 0)

      CSV.foreach(@path, headers: true) do |row|
        result.rows += 1

        store_id   = store_ids[row["Address"]]
        product_id = product_ids[row["Product Name"]]
        unless store_id && product_id
          result.unknown += 1
          next
        end

        date = row["Date"]
        event_time = times.fetch(date) { times[date] = parse_time(date) }
        unless event_time
          result.invalid += 1
          next
        end

        batch << {
          store_id: store_id,
          product_id: product_id,
          event_time: event_time,
          inventory_present: TRUE_VALUES.include?(row["Inventory Present"])
        }
        flush(batch, result) if batch.size >= BATCH_SIZE
      end

      flush(batch, result)

      Rails.logger.info "[InventoryEvents::CsvImporter] #{result.to_h}"
      result
    end

    private

    def flush(batch, result)
      return if batch.empty?

      InventoryEvent.insert_all(batch, returning: false)
      result.created += batch.size
      batch.clear
    end

    def parse_time(value)
      Date.parse(value.to_s).in_time_zone
    rescue Date::Error
      nil
    end
  end
end
