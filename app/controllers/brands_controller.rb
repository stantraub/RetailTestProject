class BrandsController < ApplicationController
  RECENT_ALERTS = 10

  def index
    @pagy, @brands = pagy(:offset, Brand.order(:name))

    @product_counts = Product.where(brand_id: @brands.map(&:id)).group(:brand_id).count
    @alert_counts   = Alert.where(brand_id: @brands.map(&:id)).group(:brand_id).count
  end

  def show
    @brand = Brand.find(params[:id])
    @products = @brand.products.order(:name).load

    @alert_count = @brand.alerts.count
    @recent_alerts = @brand.alerts.includes(:product, :store).order(triggered_at: :desc, id: :desc).limit(RECENT_ALERTS)

    @event_counts = InventoryEvent.where(product_id: @products.map(&:id)).group(:product_id).count
  end
end
