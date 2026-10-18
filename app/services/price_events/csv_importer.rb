require "csv"

module PriceEvents
  # Imports price checks from a CSV with the columns:
  #   Address, Product Name, Date, Price
  #
  # Rows with an unknown store or product, an invalid date or price, or a price
  # unchanged from the latest known one are skipped. Re-running a file is safe.
  #
  # ASSUMPTION: the file fits in memory (rows are sorted by date, so they may
  # arrive in any order). Very large files would need date-ordered chunks.
  class CsvImporter
    BATCH_SIZE = 5_000
    UNIQUE_INDEX = "index_price_events_on_product_id_and_store_id_and_event_time"

    Result = Struct.new(:rows, :created, :unchanged, :unknown, :invalid, keyword_init: true)

    def initialize(path)
      @path = path
    end

    def call
      result = Result.new(rows: 0, created: 0, unchanged: 0, unknown: 0, invalid: 0)
      candidates = read_candidates(result)
      to_insert = drop_unchanged(candidates, result)

      to_insert.each_slice(BATCH_SIZE) do |batch|
        result.created += PriceEvent.insert_all(batch, unique_by: UNIQUE_INDEX).length
      end

      Rails.logger.info "[PriceEvents::CsvImporter] #{result.to_h}"
      result
    end

    private

    def read_candidates(result)
      store_ids   = Store.pluck(:address, :id).to_h
      product_ids = Product.pluck(:name, :id).to_h
      candidates  = []

      CSV.foreach(@path, headers: true) do |row|
        result.rows += 1

        store_id   = store_ids[row["Address"]]
        product_id = product_ids[row["Product Name"]]
        unless store_id && product_id
          result.unknown += 1
          next
        end

        price      = parse_price(row["Price"])
        event_time = parse_time(row["Date"])
        unless price && event_time
          result.invalid += 1
          next
        end

        candidates << { product_id: product_id, store_id: store_id, price: price, event_time: event_time }
      end

      candidates
    end

    # "Unchanged" means the price in effect at the row's date (latest known at
    # or before it) equals its own. Comparing against that, not the newest
    # price, is what makes re-importing a no-op.
    def drop_unchanged(candidates, result)
      history = known_price_history(candidates)

      candidates.sort_by { |c| c[:event_time] }.select do |c|
        series = history[[c[:store_id], c[:product_id]]]
        next_index = series.bsearch_index { |time, _| time > c[:event_time] } || series.length
        in_effect = next_index.positive? ? series[next_index - 1] : nil

        if in_effect && in_effect[1] == c[:price]
          result.unchanged += 1
          false
        else
          series.insert(next_index, [c[:event_time], c[:price]])
          true
        end
      end
    end

    # { [store_id, product_id] => [[time, price], ...] } sorted by time.
    def known_price_history(candidates)
      history = Hash.new { |hash, key| hash[key] = [] }
      pairs = candidates.to_set { |c| [c[:store_id], c[:product_id]] }
      return history if pairs.empty?

      PriceEvent
        .where(store_id: pairs.map(&:first).uniq, product_id: pairs.map(&:last).uniq)
        .order(:event_time)
        .pluck(:store_id, :product_id, :event_time, :price)
        .each { |store_id, product_id, time, price| history[[store_id, product_id]] << [time, price] if pairs.include?([store_id, product_id]) }

      history
    end

    def parse_price(value)
      price = BigDecimal(value.to_s.delete("$,").strip).round(2)
      price.positive? ? price : nil
    rescue ArgumentError
      nil
    end

    def parse_time(value)
      Date.parse(value.to_s).in_time_zone
    rescue Date::Error
      nil
    end
  end
end
