class Api::V1::UserCartOrdersController < ApplicationController
  before_action :set_user_cart_order, only: [ :show, :update, :approve ]

  respond_to :json

  # GET /api/v1/user_cart_orders (Management only - view all orders)
  def index
    authenticate_admin_user!
    authorize_management!

    @user_cart_orders = UserCartOrder.includes(:shopping_cart, :user_address, :warehouse_orders).all
  end

  # GET /api/v1/user_cart_orders/:id (Management only)
  def show
    authenticate_admin_user!
    authorize_management!
  end

  # POST /api/v1/user_cart_orders (Users only - submit their cart as an order)
  def create
    authenticate_user!

    shopping_cart = current_user.shopping_cart

    unless shopping_cart && shopping_cart.shopping_cart_items.any?
      return render json: { error: "Cart is empty" }, status: :unprocessable_entity
    end

    # Calculate total cost
    total_cost = shopping_cart.shopping_cart_items.sum { |item| item.product.price.to_f * item.qty }

    @user_cart_order = UserCartOrder.new(
      shopping_cart: shopping_cart,
      user_address_id: user_cart_order_params[:user_address_id],
      total_cost: total_cost,
      is_paid: user_cart_order_params[:is_paid] || false,
      cart_status: "pending"
    )

    if @user_cart_order.save
      render :show, status: :created
    else
      render json: { errors: @user_cart_order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/user_cart_orders/:id/approve (Management only - approve paid orders)
  def approve
    authenticate_admin_user!
    authorize_management!

    unless @user_cart_order.is_paid
      return render json: { error: "Cannot approve unpaid order" }, status: :unprocessable_entity
    end

    if @user_cart_order.update(cart_status: "approved")
      render :show
    else
      render json: { errors: @user_cart_order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/user_cart_orders/:id (Management only - update payment status or reject)
  def update
    authenticate_admin_user!
    authorize_management!

    if @user_cart_order.update(user_cart_order_params)
      render :show
    else
      render json: { errors: @user_cart_order.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user_cart_order
    @user_cart_order = UserCartOrder.includes(
      shopping_cart: { shopping_cart_items: :product },
      user_address: { address: :country },
      warehouse_orders: [ :inventory, :company_site ]
    ).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Order not found" }, status: :not_found
  end

  def user_cart_order_params
    params.require(:user_cart_order).permit(:user_address_id, :is_paid, :cart_status)
  end

  # JWT authentication for regular users
  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    return render json: { error: "Authorization token missing" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      @current_user = User.find(decoded_token.first["sub"])

      unless @current_user.jti == decoded_token.first["jti"]
        render json: { error: "Token has been revoked" }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
    end
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

  def current_user
    @current_user
  end

  def current_admin_user
    @current_admin_user
  end
end
