class StoresController < ApplicationController
  def index
    @pagy, @stores = pagy(:offset, Store.order(:address))

    @event_counts = InventoryEvent.where(store_id: @stores.map(&:id)).group(:store_id).count
  end

  def show
    @store = Store.find(params[:id])

    # .load so the view's .empty? doesn't run a second query.
    @latest_prices = @store.price_events.latest_per_product.includes(:product).load

    @pagy, @events = pagy(:offset, @store.inventory_events.includes(product: :brand).order(event_time: :desc, id: :desc))
  end
end
