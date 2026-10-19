class ApplicationController < ActionController::Base
  include Pagy::Method

  rescue_from Pagy::RangeError do |error|
    redirect_to error.pagy.page_url(:last)
  end
end
