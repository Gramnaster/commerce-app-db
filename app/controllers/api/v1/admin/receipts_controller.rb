class Api::V1::Admin::ReceiptsController < ApplicationController
  before_action :set_receipt, only: [ :show, :destroy ]

  respond_to :json

  # GET /api/v1/admin/receipts (Management only - view all receipts)
  def index
    authenticate_admin_user!
    authorize_management!

    @receipts = Receipt.includes(:user, :user_cart_order).recent
    
    # Optional filtering by user
    if params[:user_id].present?
      @receipts = @receipts.where(user_id: params[:user_id])
    end
    
    # Optional filtering by transaction type
    if params[:transaction_type].present?
      @receipts = @receipts.where(transaction_type: params[:transaction_type])
    end
    
    # Optional filtering by date range
    if params[:start_date].present?
      @receipts = @receipts.where("created_at >= ?", params[:start_date])
    end
    
    if params[:end_date].present?
      @receipts = @receipts.where("created_at <= ?", params[:end_date])
    end
    
    # Pagination
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 20
    
    @receipts = @receipts.offset((page - 1) * per_page).limit(per_page)
    @total_count = Receipt.count
  end

  # GET /api/v1/admin/receipts/:id (Management only - view any receipt detail)
  def show
    authenticate_admin_user!
    authorize_management!
  end

  # DELETE /api/v1/admin/receipts/:id (Management only - delete receipt)
  def destroy
    authenticate_admin_user!
    authorize_management!

    if @receipt.destroy
      render json: { message: "Receipt deleted successfully" }, status: :ok
    else
      render json: { errors: @receipt.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_receipt
    @receipt = Receipt.includes(
      :user,
      user_cart_order: {
        shopping_cart: { shopping_cart_items: :product },
        user_address: { address: :country }
      }
    ).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Receipt not found" }, status: :not_found
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
