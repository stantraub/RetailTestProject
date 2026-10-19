class ProductsController < ApplicationController
  def index
    @pagy, @products = pagy(:offset, Product.includes(:brand).order(:name))

    @event_counts = InventoryEvent.where(product_id: @products.map(&:id)).group(:product_id).count
  end

  def show
    @product = Product.find(params[:id])

    # .load so the view's .empty? doesn't run a second query.
    @latest_prices = @product.price_events.latest_per_store.includes(:store).load

    @pagy, @events = pagy(:offset, @product.inventory_events.includes(:store).order(event_time: :desc, id: :desc))
  end
end
