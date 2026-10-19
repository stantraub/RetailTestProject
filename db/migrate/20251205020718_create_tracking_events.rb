class CreateTrackingEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :tracking_events do |t|
      t.boolean :inventory_present
      # index: false because the composite indexes added later start with these
      # columns, making plain ones redundant.
      t.references :product, null: false, foreign_key: true, index: false
      t.references :store, null: false, foreign_key: true, index: false
      t.datetime :event_time
      t.timestamps
    end
  end
end
