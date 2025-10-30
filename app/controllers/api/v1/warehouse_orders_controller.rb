class Api::V1::WarehouseOrdersController < ApplicationController
  include Paginatable

  before_action :authenticate_admin_user!
  before_action :set_warehouse_order, only: [ :show, :update, :destroy ]

  respond_to :json

  # GET /api/v1/warehouse_orders (Management and Warehouse)
  def index
    # Only include associations that are actually used in the view
    collection = WarehouseOrder.includes(:company_site, :inventory).all
    result = paginate_collection(collection, default_per_page: 30)
    @warehouse_orders = result[:collection]
    @pagination = result[:pagination]
  end

  # GET /api/v1/warehouse_orders/:id (Management and Warehouse)
  def show
  end

  # POST /api/v1/warehouse_orders (Management only - create warehouse order from approved cart order)
  def create
    authorize_management!

    @warehouse_order = WarehouseOrder.new(warehouse_order_params)

    if @warehouse_order.save
      # Deduct inventory quantity
      inventory = @warehouse_order.inventory
      inventory.qty_in_stock -= @warehouse_order.qty
      inventory.save

      render :show, status: :created
    else
      render json: { errors: @warehouse_order.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH /api/v1/warehouse_orders/:id (Management and Warehouse - update status)
  def update
    if @warehouse_order.update(warehouse_order_params)
      render :show
    else
      render json: { errors: @warehouse_order.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /api/v1/warehouse_orders/:id (Management only)
  def destroy
    authorize_management!

    # Return inventory quantity if order is cancelled
    if @warehouse_order.product_status == "pending"
      inventory = @warehouse_order.inventory
      inventory.qty_in_stock += @warehouse_order.qty
      inventory.save
    end

    if @warehouse_order.destroy
      render json: { message: "Warehouse order deleted successfully" }, status: :ok
    else
      render json: { errors: @warehouse_order.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_warehouse_order
    @warehouse_order = WarehouseOrder.includes(:company_site, :inventory, :user, :user_cart_order).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Warehouse order not found" }, status: :not_found
  end

  def warehouse_order_params
    params.require(:warehouse_order).permit(:company_site_id, :inventory_id, :user_id, :user_cart_order_id, :qty, :product_status)
  end

  # JWT authentication for admin users
  def authenticate_admin_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    return render json: { error: "Authorization token missing" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      @current_admin_user = AdminUser.find(decoded_token.first["sub"])

      unless @current_admin_user.jti == decoded_token.first["jti"]
        render json: { error: "Token has been revoked" }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Admin user not found" }, status: :unauthorized
    end
  end

  def authorize_management!
    unless @current_admin_user&.admin_role == "management"
      render json: { error: "Access denied. Management role required." }, status: :forbidden
    end
  end

  def current_admin_user
    @current_admin_user
  end
end
