class Api::V1::CountriesController < Api::V1::BaseController
  def index
    @countries = Country.all
  end

  def show
    @country = Country.find(params[:id])
  end
end
