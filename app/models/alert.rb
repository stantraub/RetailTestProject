class Alert < ApplicationRecord
    belongs_to :brand
    belongs_to :store
    belongs_to :product
    belongs_to :inventory_event

    # The streak_length "no" events that created this alert, oldest first.
    # Same ordering as Alerts::Detector: event_time, then id.
    def triggering_events
      InventoryEvent
        .where(store_id: store_id, product_id: product_id)
        .where("event_time < :time OR (event_time = :time AND id <= :id)",
               time: inventory_event.event_time, id: inventory_event_id)
        .order(event_time: :desc, id: :desc)
        .limit(streak_length)
        .to_a
        .reverse
    end
end
