class Api::V1::PromotionsController < ApplicationController
  include Paginatable

  before_action :authenticate_admin_user!
  before_action :authorize_management!
  before_action :set_promotion, only: [ :show, :update, :destroy ]

  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Promotion not found" }, status: :not_found
  end

  def index
    promotions = Promotion.includes(:product_categories, :products).all

    result = paginate_collection(promotions, default_per_page: 20)
    @promotions = result[:collection]
    @pagination = result[:pagination]

    render :index
  end

  def show
    render :show
  end

  def create
    @promotion = Promotion.new(promotion_params)

    if @promotion.save
      render :show, status: :created
    else
      render json: { errors: @promotion.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @promotion.update(promotion_params)
      render :show
    else
      render json: { errors: @promotion.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @promotion.destroy
      render json: { message: "Promotion deleted successfully" }, status: :ok
    else
      render json: { errors: @promotion.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  # Custom JWT authentication for admin_user
  def authenticate_admin_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    return render json: { error: "Missing authentication token" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      payload = decoded_token.first

      unless payload["scp"] == "admin_user"
        return render json: { error: "Invalid token scope" }, status: :unauthorized
      end

      @current_admin_user = AdminUser.find(payload["sub"])

      unless @current_admin_user.jti == payload["jti"]
        render json: { error: "Token has been revoked" }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Admin user not found" }, status: :unauthorized
    end
  end

  def current_admin_user
    @current_admin_user
  end

  def authorize_management!
    unless current_admin_user&.management?
      render json: { error: "Unauthorized. Management role required." }, status: :forbidden
    end
  end

  def set_promotion
  @promotion = Promotion.includes(:product_categories, :products).find(params[:id])
  end

  def promotion_params
    params.require(:promotion).permit(:discount_amount)
  end
end
