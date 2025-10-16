# frozen_string_literal: true

class Api::V1::AdminUsers::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  skip_before_action :require_no_authentication, only: [ :create ]
  skip_before_action :verify_signed_out_user, only: [ :destroy ]
  before_action :authenticate_admin_user_via_jwt!, only: [ :destroy ]

  respond_to :json

  # Disable new action for API (no login form needed)
  def new
    render json: { error: "Use POST /api/v1/admin_users/login to authenticate" }, status: :method_not_allowed
  end

  def create
    self.resource = warden.authenticate!(auth_options)

    # Check if admin is confirmed (if confirmable is enabled)
    unless resource.confirmed?
      sign_out(resource)
      return render json: {
        status: { code: 401, message: "Please confirm your email address before logging in." },
        errors: [ "Email not confirmed" ]
      }, status: :unauthorized
    end

    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  rescue Warden::NotAuthenticated
    render json: {
      status: { code: 401, message: "Invalid email or password." },
      errors: [ "Authentication failed" ]
    }, status: :unauthorized
  end

  # Override destroy to handle JWT logout
  def destroy
    authenticate_admin_user_via_jwt!

    if @current_admin_user
      # Revoke the JWT token by updating the jti
      @current_admin_user.update(jti: SecureRandom.uuid)
      render json: { status: 200, message: "Logged out successfully." }, status: :ok
    else
      render json: { status: 401, message: "Couldn't find an active session." }, status: :unauthorized
    end
  end

  private
  def respond_with(resource, _opts = {})
    # The `resource` is the signed-in admin user.
    # Let Rails render the view at:
    # app/views/api/v1/admin_users/sessions/create.json.props
    render :create, status: :ok
  end

  # For logout, a simple JSON response is still the most pragmatic.
  def respond_to_on_destroy
    if @current_admin_user
      render json: { status: 200, message: "Logged out successfully." }, status: :ok
    else
      render json: { status: 401, message: "Couldn't find an active session." }, status: :unauthorized
    end
  end

  # Custom JWT authentication for logout
  def authenticate_admin_user_via_jwt!
    token = request.headers["Authorization"]&.split(" ")&.last
    return unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      payload = decoded_token.first

      # Check if the token is for admin_user scope and set the user
      if payload["scp"] == "admin_user"
        @current_admin_user = AdminUser.find(payload["sub"])
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      # Token is invalid, @current_admin_user will remain nil
      @current_admin_user = nil
    end
  end

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
