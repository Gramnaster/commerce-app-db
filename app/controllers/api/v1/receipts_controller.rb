class Api::V1::ReceiptsController < ApplicationController
  include Paginatable

  before_action :authenticate_user_or_admin!
  before_action :set_receipt, only: [ :show ]
  before_action :authorize_receipt_access!, only: [ :show ]

  respond_to :json

  # GET /api/v1/receipts (Users only - view their own transaction history)
  def index
    # Management admins can view all receipts with optional user_id filter
    if current_admin_user&.management?
      collection = if params[:user_id].present?
        Receipt.where(user_id: params[:user_id])
      else
        Receipt.all
      end.includes(
        { user: :user_detail },
        { user_cart_order: :warehouse_orders }
      ).recent
    else
      # Regular users see only their own receipts
      collection = current_user.receipts.includes(
        { user: :user_detail },
        { user_cart_order: :warehouse_orders }
      ).recent
    end

    # Optional filtering by transaction type
    if params[:transaction_type].present?
      collection = collection.where(transaction_type: params[:transaction_type])
    end

    result = paginate_collection(collection, default_per_page: 20)
    @receipts = result[:collection]
    @pagination = result[:pagination]
  end

  # GET /api/v1/receipts/:id (Users view their own, Management admins view any)
  def show
    # Authorization handled by before_action :authorize_receipt_access!
  end

  # GET /api/v1/receipts/latest (Get the most recent receipt for the current user)
  def latest
    # Users get their own latest receipt, admins need to specify user_id
    if current_admin_user&.management?
      if params[:user_id].present?
        user = User.find(params[:user_id])
        @receipt = user.receipts
          .includes(
            :user,
            user_cart_order: {
              shopping_cart: :shopping_cart_items,
              address: :country,
              warehouse_orders: { inventory: :product, company_site: :address }
            }
          )
          .order(created_at: :desc)
          .first
      else
        return render json: { error: "user_id parameter required for admin access" }, status: :unprocessable_content
      end
    elsif current_user
      @receipt = current_user.receipts
        .includes(
          :user,
          user_cart_order: {
            shopping_cart: :shopping_cart_items,
            address: :country,
            warehouse_orders: { inventory: :product, company_site: :address }
          }
        )
        .order(created_at: :desc)
        .first
    else
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    if @receipt
      render :show
    else
      render json: { error: "No receipts found" }, status: :not_found
    end
  end

  private

  def set_receipt
    @receipt = Receipt.includes(
      :user,
      user_cart_order: {
        shopping_cart: :shopping_cart_items,
        address: :country,
        warehouse_orders: { inventory: :product, company_site: :address }
      }
    ).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Receipt not found" }, status: :not_found
  end

  # Authorization check for receipt access
  def authorize_receipt_access!
    # Management admins can view any receipt
    return if current_admin_user&.management?

    # Regular users can only view their own receipts
    unless current_user&.id == @receipt.user_id
      render json: { error: "Access denied. You can only view your own receipts." }, status: :forbidden
    end
  end

  # Authenticate either user or admin (follows users_controller pattern)
  def authenticate_user_or_admin!
    token = request.headers["Authorization"]&.split(" ")&.last
    return render json: { error: "Missing authentication token" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      payload = decoded_token.first

      if payload["scp"] == "admin_user"
        # Admin user authentication
        @current_admin_user = AdminUser.find(payload["sub"])

        # Verify JTI for admin users
        unless @current_admin_user.jti == payload["jti"]
          return render json: { error: "Token has been revoked" }, status: :unauthorized
        end

        # SECURITY CHECK: Only management admins can access receipts
        unless @current_admin_user.management?
          render json: { error: "Forbidden. Management role required." }, status: :forbidden
        end
      elsif payload["scp"] == "user"
        # Regular user authentication
        @current_user = User.find(payload["sub"])

        # Verify JTI for regular users
        unless @current_user.jti == payload["jti"]
          render json: { error: "Token has been revoked" }, status: :unauthorized
        end
      else
        render json: { error: "Invalid token scope" }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
    end
  end

  # Helper to get current admin user
  def current_admin_user
    @current_admin_user
  end

  # Helper to get current user
  def current_user
    @current_user
  end
end
