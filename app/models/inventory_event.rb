class InventoryEvent < ApplicationRecord
    belongs_to :product
    belongs_to :store
    has_one :alert
end
