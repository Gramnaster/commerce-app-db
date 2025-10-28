class Api::V1::CompanySitesController < ApplicationController
  include Paginatable

  before_action :authenticate_admin_user!
  before_action :authorize_admin_user!, only: [ :index, :show ]

  respond_to :json

  def show
    # Only management can view a company site
    unless current_admin_user.management?
      return render json: { error: "Unauthorized. Higher permissions required." }, status: :forbidden
    end

    @company_site = CompanySite.find(params[:id])
    render :show
  end

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
    # Only management can view all company sites
    unless current_admin_user.management?
      return render json: { error: "Unauthorized. Higher permissions required." }, status: :forbidden
    end

    collection = CompanySite.all
    result = paginate_collection(collection, 20)
    @company_sites = result[:collection]
    @pagination = result[:pagination]
    render :index
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

  def authorize_management!
    unless current_admin_user.management?
      render json: { error: "Unauthorized. Management role required." }, status: :forbidden
    end
  end
end
