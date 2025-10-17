class Api::V1::ReceiptsController < ApplicationController
  before_action :set_receipt, only: [ :show ]

  respond_to :json

  # GET /api/v1/receipts (Users only - view their own transaction history)
  def index
    authenticate_user!

    @receipts = current_user.receipts.includes(:user_cart_order).recent

    # Optional filtering by transaction type
    if params[:transaction_type].present?
      @receipts = @receipts.where(transaction_type: params[:transaction_type])
    end
  end

  # GET /api/v1/receipts/:id (Users only - view their own receipt detail)
  def show
    authenticate_user!

    unless @receipt.user_id == current_user.id
      render json: { error: "Access denied. You can only view your own receipts." }, status: :forbidden
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

  def current_user
    @current_user
  end
end
