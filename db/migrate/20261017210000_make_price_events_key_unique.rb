class MakePriceEventsKeyUnique < ActiveRecord::Migration[7.1]
  INDEX_COLUMNS = [:product_id, :store_id, :event_time].freeze

  def change
    # One price per product, store and time (makes imports idempotent).
    remove_index :price_events, column: INDEX_COLUMNS
    add_index :price_events, INDEX_COLUMNS, unique: true
  end
end
