class Api::V1::CountriesController < Api::V1::BaseController
  include Paginatable

  skip_before_action :authenticate_user!, only: [ :index, :show ]
  def index
    collection = Country.all
    result = paginate_collection(collection, 50)
    @countries = result[:collection]
    @pagination = result[:pagination]
  end

  def show
    @country = Country.find(params[:id])
  end
end
