class PriceEvent < ApplicationRecord
  belongs_to :product
  belongs_to :store

  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :event_time, presence: true, uniqueness: { scope: [:product_id, :store_id] }

  # The newest price for each store, newest first. Call on one product's price
  # events. DISTINCT ON forces its own ordering, so it runs as a subquery and
  # the result is sorted by date afterwards.
  scope :latest_per_store, -> {
    latest = select("DISTINCT ON (price_events.store_id) price_events.*")
      .order("price_events.store_id, price_events.event_time DESC")
    unscoped.from(latest, :price_events).order(event_time: :desc, id: :desc)
  }

  # The newest price for each product, newest first. Call on one store's price events.
  scope :latest_per_product, -> {
    latest = select("DISTINCT ON (price_events.product_id) price_events.*")
      .order("price_events.product_id, price_events.event_time DESC")
    unscoped.from(latest, :price_events).order(event_time: :desc, id: :desc)
  }
end
