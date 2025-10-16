# frozen_string_literal: true

class Api::V1::AdminUsers::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  skip_before_action :require_no_authentication, only: [ :create ]
  skip_before_action :verify_signed_out_user, only: [ :destroy ]

  respond_to :json

  # Disable new action for API (no login form needed)
  def new
    render json: { error: "Use POST /api/v1/admin_users/login to authenticate" }, status: :method_not_allowed
  end

  def create
    self.resource = warden.authenticate!(auth_options)

    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
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
    if current_admin_user
      render json: { status: 200, message: "Logged out successfully." }, status: :ok
    else
      render json: { status: 401, message: "Couldn't find an active session." }, status: :unauthorized
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
