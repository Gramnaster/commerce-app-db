class Api::V1::PromotionsCategoriesController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :authorize_management!
  before_action :set_promotions_category, only: [ :show, :destroy ]

  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Promotions category association not found" }, status: :not_found
  end

  def index
    @promotions_categories = PromotionsCategory.includes(:product_category, :promotion).all
    render :index
  end

  def show
    render :show
  end

  def create
    @promotions_category = PromotionsCategory.new(promotions_category_params)

    if @promotions_category.save
      render :show, status: :created
    else
      render json: { errors: @promotions_category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @promotions_category.destroy
      render json: { message: "Promotion-category association deleted successfully" }, status: :ok
    else
      render json: { errors: @promotions_category.errors.full_messages }, status: :unprocessable_entity
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

  def set_promotions_category
    @promotions_category = PromotionsCategory.includes(:product_category, :promotion).find(params[:id])
  end

  def promotions_category_params
    params.require(:promotions_category).permit(:product_categories_id, :promotions_id)
  end
end
