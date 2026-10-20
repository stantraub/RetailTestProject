module Alerts
  # Creates an alert for the product's brand when a store reports "no inventory"
  # streak_length times in a row for a product (ordered by event_time, then id).
  #
  # - Each run of consecutive "no" events gets an id (a running count of the
  #   events that are not "no"), and the "no"s are numbered within their run.
  #   The event where that number reaches streak_length gets the alert, so any
  #   streak length is the same query and a longer run still makes one alert.
  # - Only an explicit false counts as "no"; anything else, including NULL
  #   (unknown), ends the run.
  class Detector
    SQL = <<~SQL.squish.freeze
      WITH runs AS (
        SELECT
          id, store_id, product_id, event_time, inventory_present,
          COUNT(*) FILTER (WHERE inventory_present IS DISTINCT FROM false) OVER w AS run_id
        FROM inventory_events
        WINDOW w AS (PARTITION BY store_id, product_id ORDER BY event_time, id)
      ),
      counted AS (
        SELECT
          id, store_id, product_id, event_time, inventory_present,
          COUNT(*) FILTER (WHERE inventory_present = false)
            OVER (PARTITION BY store_id, product_id, run_id ORDER BY event_time, id) AS nos_in_run
        FROM runs
      )
      INSERT INTO alerts
        (brand_id, store_id, product_id, inventory_event_id, streak_length, triggered_at, created_at, updated_at)
      SELECT
        products.brand_id, counted.store_id, counted.product_id,
        counted.id, :streak_length, counted.event_time, NOW(), NOW()
      FROM counted
      JOIN products ON products.id = counted.product_id
      WHERE counted.inventory_present = false
        AND counted.nos_in_run = :streak_length
      ON CONFLICT (inventory_event_id) DO NOTHING
    SQL

    attr_reader :streak_length

    def initialize(streak_length: Rails.configuration.x.alerts.streak_length)
      @streak_length = Integer(streak_length)
      raise ArgumentError, "streak_length must be at least 1, got #{@streak_length}" if @streak_length < 1
    end

    def call
      sql = ActiveRecord::Base.sanitize_sql([SQL, { streak_length: streak_length }])
      created = ActiveRecord::Base.connection.execute(sql).cmd_tuples
      Rails.logger.info "[Alerts::Detector] streak_length=#{streak_length} created=#{created}"
      created
    end
  end
end
