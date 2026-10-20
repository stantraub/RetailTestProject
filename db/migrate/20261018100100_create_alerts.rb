class CreateAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :alerts do |t|
      # brand_id is derivable through the product, but storing it makes
      # "alerts for this brand" a direct indexed lookup.
      t.references :brand, null: false, foreign_key: true, index: false
      t.references :store, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      # Unique: an event triggers at most one alert, so detection can be re-run.
      t.references :inventory_event, null: false, foreign_key: true, index: { unique: true }

      t.datetime :triggered_at, null: false

      t.timestamps
    end

    add_index :alerts, [:brand_id, :triggered_at]
  end
end
