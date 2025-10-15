class Api::V1::ProductsController < ApplicationController

  private

  def product_params
    permit.require(:product)
  end
end
