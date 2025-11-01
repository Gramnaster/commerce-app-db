class Api::V1::UserCartOrdersController < ApplicationController
  include Paginatable

  before_action :set_user_cart_order, only: [ :show, :update, :approve ]

  respond_to :json

  # GET /api/v1/user_cart_orders (Management only - view all orders)
  def index
    authenticate_admin_user!
    authorize_management!

    # Eager load associations used in view: address, shopping_cart.shopping_cart_items
    collection = UserCartOrder.includes(
      :address,
      :user,
      { shopping_cart: :shopping_cart_items },
      :warehouse_orders
    ).all
    result = paginate_collection(collection, default_per_page: 30)
    @user_cart_orders = result[:collection]
    @pagination = result[:pagination]
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
      return render json: { error: "Cart is empty" }, status: :unprocessable_content
    end

    # Eager load products with promotion and product_category for final_price calculation
    shopping_cart_items = shopping_cart.shopping_cart_items.includes(product: [ :promotion, :product_category ])

    # Calculate total cost with promotions applied
    total_cost = shopping_cart_items.sum { |item| item.product.final_price.to_f * item.qty }

    # Get user's payment method
    payment_method = current_user.user_payment_methods.first

    unless payment_method
      return render json: { error: "Payment method not found" }, status: :not_found
    end

    # Check if user has sufficient balance
    unless payment_method.sufficient_balance?(total_cost)
      return render json: {
        error: "Insufficient funds",
        required: total_cost,
        current_balance: payment_method.balance,
        shortfall: (total_cost - payment_method.balance).round(2)
      }, status: :unprocessable_content
    end

    # Create the order in a transaction
    ActiveRecord::Base.transaction do
      @user_cart_order = UserCartOrder.new(
        shopping_cart: shopping_cart,
        address_id: user_cart_order_params[:address_id],
        user_id: current_user.id,
        social_program_id: user_cart_order_params[:social_program_id],
        total_cost: total_cost,
        is_paid: true,
        cart_status: "approved"  # Auto-approve paid orders
      )

      if @user_cart_order.save
        # Deduct the amount from user's balance
        withdraw_result = payment_method.withdraw(
          total_cost,
          description: "Payment for Order ##{@user_cart_order.id}"
        )

        unless withdraw_result[:success]
          raise ActiveRecord::Rollback
        end

        # Create receipt for the purchase
        Receipt.create!(
          user: current_user,
          user_cart_order: @user_cart_order,
          transaction_type: "purchase",
          amount: total_cost,
          balance_before: payment_method.balance + total_cost, # Balance before withdrawal
          balance_after: payment_method.balance,
          description: "Purchase - Order ##{@user_cart_order.id}"
        )

        # Automatically assign warehouses and create warehouse orders
        assignment_service = AssignWarehouseToOrderService.new(@user_cart_order)
        assignment_result = assignment_service.call

        if assignment_result[:success]
          Rails.logger.info("[UserCartOrder] Warehouse assignment successful for order ##{@user_cart_order.id}")
          if assignment_result[:errors].any?
            Rails.logger.warn("[UserCartOrder] Partial assignment with errors: #{assignment_result[:errors].join(', ')}")
          end
        else
          # Log error but don't fail the order - admin can manually assign later
          Rails.logger.error("[UserCartOrder] Warehouse assignment failed for order ##{@user_cart_order.id}: #{assignment_result[:errors].join(', ')}")
        end

        render :show, status: :created
      else
        render json: { errors: @user_cart_order.errors.full_messages }, status: :unprocessable_content
      end
    end
  end

  # PATCH /api/v1/user_cart_orders/:id/approve (Management only - approve paid orders)
  def approve
    authenticate_admin_user!
    authorize_management!

    unless @user_cart_order.is_paid
      return render json: { error: "Cannot approve unpaid order" }, status: :unprocessable_content
    end

    if @user_cart_order.update(cart_status: "approved")
      render :show
    else
      render json: { errors: @user_cart_order.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH /api/v1/user_cart_orders/:id (Management only - update payment status or reject)
  def update
    authenticate_admin_user!
    authorize_management!

    if @user_cart_order.update(user_cart_order_params)
      render :show
    else
      render json: { errors: @user_cart_order.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_user_cart_order
    @user_cart_order = UserCartOrder.includes(
      :address,
      :user,
      shopping_cart: { shopping_cart_items: :product },
      warehouse_orders: [ :inventory, :company_site ]
    ).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Order not found" }, status: :not_found
  end

  def user_cart_order_params
    params.require(:user_cart_order).permit(:address_id, :is_paid, :cart_status, :social_program_id)
  end

  # JWT authentication for regular users
  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    return render json: { error: "Authorization token missing" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      @current_user = User.find(decoded_token.first["sub"])

      unless @current_user.jti == decoded_token.first["jti"]
        render json: { error: "Token has been revoked" }, status: :unauthorized and return
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized and return
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized and return
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
        render json: { error: "Token has been revoked" }, status: :unauthorized and return
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized and return
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Admin user not found" }, status: :unauthorized and return
    end
  end

  def authorize_management!
    unless @current_admin_user&.admin_role == "management"
      render json: { error: "Access denied. Management role required." }, status: :forbidden and return
    end
  end

  def current_user
    @current_user
  end

  def current_admin_user
    @current_admin_user
  end
end
