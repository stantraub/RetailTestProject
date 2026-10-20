class AlertsController < ApplicationController
  def index
    scope = Alert.all
    scope = scope.where(brand_id: params[:brand_id]) if params[:brand_id].present?

    @brand = Brand.find_by(id: params[:brand_id]) if params[:brand_id].present?
    @pagy, @alerts = pagy(:offset, scope.includes(:brand, :store, :product).order(triggered_at: :desc, id: :desc))
  end

  def show
    @alert = Alert.includes(:brand, :store, :product, :inventory_event).find(params[:id])
    @events = @alert.triggering_events
  end
end
