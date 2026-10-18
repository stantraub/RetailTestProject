class CreatePriceEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :price_events do |t|
      t.references :product, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false
      t.datetime :event_time, null: false

      t.timestamps
    end

    add_index :price_events, [:product_id, :store_id, :event_time]
  end
end
