class RenameTrackingEventsToInventoryEvents < ActiveRecord::Migration[7.1]
  def change
    rename_table :tracking_events, :inventory_events
  end
end
