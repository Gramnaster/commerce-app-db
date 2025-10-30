class Api::V1::SocialProgramReceiptsController < ApplicationController
  include Paginatable

  before_action :set_social_program_receipt, only: [ :show, :destroy ]

  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Social program receipt not found" }, status: :not_found
  end

  def index
    collection = SocialProgramReceipt.includes(:receipt, social_program: { address: :country }).all
    result = paginate_collection(collection, default_per_page: 20)
    @social_program_receipts = result[:collection]
    @pagination = result[:pagination]
    render :index
  end

  def show
    render :show
  end

  def create
    @social_program_receipt = SocialProgramReceipt.new(social_program_receipt_params)

    if @social_program_receipt.save
      @social_program_receipt = SocialProgramReceipt.includes(:receipt, social_program: { address: :country }).find(@social_program_receipt.id)
      render :show, status: :created
    else
      render json: {
        status: { code: 422, message: "Social program receipt association creation failed" },
        errors: @social_program_receipt.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  def destroy
    @social_program_receipt.destroy
    render json: {
      status: { code: 200, message: "Social program receipt association deleted successfully" }
    }, status: :ok
  end

  private

  def set_social_program_receipt
    @social_program_receipt = SocialProgramReceipt.includes(:receipt, social_program: { address: :country }).find(params[:id])
  end

  def social_program_receipt_params
    params.require(:social_program_receipt).permit(:social_program_id, :receipt_id)
  end
end
