class BrandsController < ApplicationController
  def index
    @pagy, @brands = pagy(:offset, Brand.order(:name))

    @product_counts = Product.where(brand_id: @brands.map(&:id)).group(:brand_id).count
  end

  def show
    @brand = Brand.find(params[:id])
    @products = @brand.products.order(:name).load

    @event_counts = InventoryEvent.where(product_id: @products.map(&:id)).group(:product_id).count
  end
end
