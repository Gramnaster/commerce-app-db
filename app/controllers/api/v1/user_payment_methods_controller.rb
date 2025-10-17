class Api::V1::UserPaymentMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_method

  respond_to :json

  # GET /api/v1/user_payment_methods/balance
  def balance
    render json: {
      balance: @payment_method.balance,
      user_id: current_user.id,
      email: current_user.email
    }, status: :ok
  end

  # POST /api/v1/user_payment_methods/deposit
  def deposit
    amount = params[:amount].to_f

    if amount <= 0
      return render json: { error: "Amount must be greater than zero" }, status: :unprocessable_entity
    end

    result = @payment_method.deposit(amount)

    if result[:success]
      render json: {
        message: "Deposit successful",
        amount_deposited: amount,
        new_balance: result[:new_balance]
      }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/user_payment_methods/withdraw
  def withdraw
    amount = params[:amount].to_f

    if amount <= 0
      return render json: { error: "Amount must be greater than zero" }, status: :unprocessable_entity
    end

    result = @payment_method.withdraw(amount)

    if result[:success]
      render json: {
        message: "Withdrawal successful",
        amount_withdrawn: amount,
        new_balance: result[:new_balance]
      }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def set_payment_method
    @payment_method = current_user.user_payment_methods.first

    unless @payment_method
      render json: { error: "Payment method not found" }, status: :not_found
    end
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
