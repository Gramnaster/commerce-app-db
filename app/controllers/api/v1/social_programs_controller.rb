class Api::V1::SocialProgramsController < ApplicationController
  include Paginatable

  before_action :set_social_program, only: [ :show, :update, :destroy ]

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

  def create
    @social_program = SocialProgram.new(social_program_params)

    if @social_program.save
      render :show, status: :created
    else
      render json: {
        status: { code: 422, message: "Social program creation failed" },
        errors: @social_program.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  def update
    if @social_program.update(social_program_params)
      render :show
    else
      render json: {
        status: { code: 422, message: "Social program update failed" },
        errors: @social_program.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  def destroy
    @social_program.destroy
    render json: {
      status: { code: 200, message: "Social program deleted successfully" }
    }, status: :ok
  end

  private

  def set_social_program
    @social_program = SocialProgram.includes(address: :country).find(params[:id])
  end

  def social_program_params
    params.require(:social_program).permit(:title, :description, :address_id)
  end
end
