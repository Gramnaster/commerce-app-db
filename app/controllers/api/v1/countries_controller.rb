class Api::V1::CountriesController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [ :index, :show ]
  def index
    @countries = Country.all
  end

  def show
    @country = Country.find(params[:id])
  end
end
