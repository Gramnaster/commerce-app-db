class Api::V1::AdminUsersController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :set_admin_user, only: [ :show, :update, :destroy ]
  before_action :authorize_admin_user!, only: [ :show, :update ]

  respond_to :json

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Admin user not found" }, status: :not_found
  end

  private

  # Custom JWT authentication for admin_user
  def authenticate_admin_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    return render json: { error: "Missing authentication token" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      payload = decoded_token.first

      # Check if the token is for admin_user scope
      unless payload["scp"] == "admin_user"
        return render json: { error: "Invalid token scope" }, status: :unauthorized
      end

      @current_admin_user = AdminUser.find(payload["sub"])

      # Verify the JTI matches (token hasn't been revoked)
      unless @current_admin_user.jti == payload["jti"]
        render json: { error: "Token has been revoked" }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Admin user not found" }, status: :unauthorized
    end
  end

  # Helper method to access current admin user
  def current_admin_user
    @current_admin_user
  end

  public

  def index
    # Only management can view all admin users
    unless current_admin_user.management?
      return render json: { error: "Unauthorized. Higher permissions required." }, status: :forbidden
    end

    @admin_users = AdminUser.includes(:admin_detail, :admin_phones, :admin_addresses, company_sites: :address).all
    render :index
  end

  def show
  end

  def create
    @admin_user = AdminUser.new(admin_user_params)
    @admin_user.password = params[:password] if params[:password].present?
    @admin_user.password_confirmation = params[:password_confirmation] if params[:password_confirmation].present?

    if @admin_user.save
      render :create, status: :created
    else
      render json: { errors: @admin_user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @admin_user.update(admin_user_params)
      render :update
    else
      render json: { errors: @admin_user.errors.full_messages  }, status: :unprocessable_content
    end
  end

  def destroy
    if @admin_user.destroy
      render json: { message: "Admin user deleted successfully" }, status: :ok
    else
      render json: { errors: @admin_user.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_admin_user
    @admin_user = AdminUser.includes(:admin_detail, :admin_phones, :admin_addresses,
                                      :addresses, company_sites: :address).find(params[:id])
  end

  def authorize_admin_user!
    # Management role can view any admin user
    return if current_admin_user.management?

    # Warehouse role can only view themselves
    unless current_admin_user.id == @admin_user.id
      render json: { error: "Unauthorized. You can only view your own profile." }, status: :forbidden
    end
  end

  def admin_user_params
    params.require(:admin_user).permit(
      :email, :password, :password_confirmation,
      admin_detail_attributes: [ :id, :first_name, :middle_name, :last_name, :dob, :_destroy ],
      admin_phones_attributes: [ :id, :phone_no, :phone_type, :_destroy ],
      admin_addresses_attributes: [
        :id, :is_default, :_destroy,
        address_attributes: [ :id, :unit_no, :street_no, :address_line1, :address_line2,
                            :city, :region, :zipcode, :country_id ]
      ]
    )
  end
end
