class Api::V1::ProducersController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :authorize_management!
  before_action :set_producer, only: [ :show, :update, :destroy ]

  respond_to :json

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Producer not found" }, status: :not_found
  end

  def index
    @producers = Producer.includes(:address).all
    render :index
  end

  def show
    render :show
  end

  def create
    @producer = Producer.new(producer_params)

    if @producer.save
      render :show, status: :created
    else
      render json: { errors: @producer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @producer.update(producer_params)
      render :show
    else
      render json: { errors: @producer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @producer.destroy
      render json: { message: "Producer deleted successfully" }, status: :ok
    else
      render json: { errors: @producer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Custom JWT authentication for admin_user
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

  def set_producer
    @producer = Producer.includes(:address).find(params[:id])
  end

  def producer_params
    params.require(:producer).permit(
      :title,
      :address_id,
      address_attributes: [
        :id, :unit_no, :street_no, :address_line1, :address_line2,
        :city, :region, :zipcode, :country_id
      ]
    )
  end
end
