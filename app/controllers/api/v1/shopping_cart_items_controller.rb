class Api::V1::ShoppingCartItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shopping_cart
  before_action :set_shopping_cart_item, only: [:show, :update, :destroy]

  respond_to :json

  # GET /api/v1/shopping_cart_items
  def index
    @shopping_cart_items = @shopping_cart.shopping_cart_items.includes(:product)
  end

  # GET /api/v1/shopping_cart_items/:id
  def show
  end

  # POST /api/v1/shopping_cart_items
  def create
    @shopping_cart_item = @shopping_cart.shopping_cart_items.build(shopping_cart_item_params)

    if @shopping_cart_item.save
      render :show, status: :created
    else
      render json: { errors: @shopping_cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/shopping_cart_items/:id
  def update
    if @shopping_cart_item.update(shopping_cart_item_params)
      render :show
    else
      render json: { errors: @shopping_cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/shopping_cart_items/:id
  def destroy
    if @shopping_cart_item.destroy
      render json: { message: "Item removed from cart successfully" }, status: :ok
    else
      render json: { errors: @shopping_cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_shopping_cart
    @shopping_cart = current_user.shopping_cart
    
    unless @shopping_cart
      render json: { error: "Shopping cart not found" }, status: :not_found
    end
  end

  def set_shopping_cart_item
    @shopping_cart_item = @shopping_cart.shopping_cart_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Item not found in your cart" }, status: :not_found
  end

  def shopping_cart_item_params
    params.require(:shopping_cart_item).permit(:product_id, :qty)
  end

  # JWT authentication for regular users
  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    return render json: { error: "Authorization token missing" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      @current_user = User.find(decoded_token.first["sub"])

      # JTI validation for revoked tokens
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
