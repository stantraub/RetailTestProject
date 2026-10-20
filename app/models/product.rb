class Product < ApplicationRecord
    belongs_to :brand
    has_many :inventory_events
    has_many :price_events
    has_many :alerts
end
