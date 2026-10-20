class AddLookupIndexToInventoryEvents < ActiveRecord::Migration[7.1]
  def change
    # Matches the alert detector's window: partition by store and product, order by time.
    add_index :inventory_events, [:store_id, :product_id, :event_time]
  end
end
