class Api::V1::ProductCategoriesController < ApplicationController
  before_action :authenticate_admin_user!, except: [ :index, :show ]
  before_action :authorize_management!, except: [ :index, :show ]
  before_action :set_product_category, only: [ :show, :update, :destroy ]

  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Product category not found" }, status: :not_found
  end

  def index
  @product_categories = ProductCategory.includes(:products).all
  render :index
  end

  def show
    render :show
  end

  def create
    @product_category = ProductCategory.new(product_category_params)

    if @product_category.save
      render :show, status: :created
    else
      render json: { errors: @product_category.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @product_category.update(product_category_params)
      render :show
    else
      render json: { errors: @product_category.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @product_category.destroy
      render json: { message: "Product category deleted successfully" }, status: :ok
    else
      render json: { errors: @product_category.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  # Custom JWT authentication for admin_user (reuse from AdminUsersController pattern)
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

  def set_product_category
  @product_category = ProductCategory.includes(products: :promotion).find(params[:id])
  end

  def product_category_params
    params.require(:product_category).permit(:title, :products_id)
  end
end
