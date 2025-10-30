class Api::V1::SocialProgramsController < ApplicationController
  include Paginatable

  before_action :set_social_program, only: [ :show ]

  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Social Program not found" }, status: :not_found
  end

  def index
    social_programs = SocialProgram.includes(address: :country).all

    result = paginate_collection(social_programs, default_per_page: 10)
    @social_programs = result[:collection]
    @pagination = result[:pagination]

    render :index
  end

  def show
    render :show
  end

  private

  def set_social_program
    @social_program = SocialProgram.includes(address: :country).find(params[:id])
  end
end
