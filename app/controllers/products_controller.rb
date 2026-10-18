class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
    @latest_prices = @product.price_events.latest_per_store.includes(:store)
  end
end

