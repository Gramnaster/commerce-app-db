class Api::V1::ProductsController < ApplicationController
  before_action :authenticate_admin_user!, only: [ :create, :update, :destroy ]
  before_action :authorize_management!, only: [ :create, :update, :destroy ]
  before_action :set_product, only: [ :show, :update, :destroy ]

  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Product not found" }, status: :not_found
  end

  def index
    @products = Product.includes(
      { producer: { address: :country } },
      :promotion,
      product_category: :promotions
    ).all
  end

  def show
  end

  def top_newest
    @products = Product.includes(
      :producer,
      :promotion,
      product_category: :promotions
    ).order(created_at: :desc).limit(4)
    render :top_newest
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      render :create, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @product.update(product_params)
      render :update
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @product.destroy
      render json: { message: "Product deleted successfully" }, status: :ok
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_content
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

  def set_product
    @product = Product.includes(
      { producer: { address: :country } },
      :promotion,
      product_category: :promotions
    ).find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :title, :description, :price, :product_image_url,
      :product_category_id, :producer_id, :promotion_id
    )
  end
end
