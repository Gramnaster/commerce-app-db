class Api::V1::InventoriesController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :set_inventory, only: [ :show, :update, :destroy ]

  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Inventory not found" }, status: :not_found
  end

  def index
    @inventories = Inventory.includes(:company_site, :product).all
  end

  def show
  end

  def create
    @inventory = Inventory.new(inventory_params)

    if @inventory.save
      render :show, status: :created
    else
      render json: { errors: @inventory.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @inventory.update(inventory_params)
      render :show
    else
      render json: { errors: @inventory.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @inventory.destroy
      render json: { message: "Inventory deleted successfully" }, status: :ok
    else
      render json: { errors: @inventory.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_inventory
    @inventory = Inventory.includes(:company_site, :product).find(params[:id])
  end

  # Custom JWT authentication for admin_user
  def authenticate_admin_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    return render json: { error: "Authorization token missing" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      @current_admin_user = AdminUser.find(decoded_token.first["sub"])

      # JTI validation for revoked tokens
      unless @current_admin_user.jti == decoded_token.first["jti"]
        render json: { error: "Token has been revoked" }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Admin user not found" }, status: :unauthorized
    end
  end

  def inventory_params
    params.require(:inventory).permit(:company_site_id, :product_id, :sku, :qty_in_stock)
  end
end
