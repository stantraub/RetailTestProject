class AddEventTimeIndexesToInventoryEvents < ActiveRecord::Migration[7.1]
  def change
    # For the newest-first, paginated event lists on the store and product pages.
    add_index :inventory_events, [:store_id, :event_time]
    add_index :inventory_events, [:product_id, :event_time]
  end
end
