class StoresController < ApplicationController
  def index
    @stores = Store.all
  end

  def show
    @store = Store.find(params[:id])
    @latest_prices = @store.price_events.latest_per_product.includes(:product)
  end
end

