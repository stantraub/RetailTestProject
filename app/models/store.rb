class Store < ApplicationRecord
    has_many :inventory_events
    has_many :price_events
    has_many :alerts
end
