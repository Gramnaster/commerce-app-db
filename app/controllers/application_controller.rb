class ApplicationController < ActionController::API
  # before_action :configure_permitted_parameters, if: :devise_controller?

  # def options
  #   response.headers["Access-Control-Allow-Origin"] = "*"
  #   response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD"
  #   response.headers["Access-Control-Allow-Headers"] = "*"
  #   response.headers["Access-Control-Expose-Headers"] = "Authorization"
  #   response.headers["Access-Control-Max-Age"] = "7200"
  #   head :ok
  # end

  # def preflight
  #   response.headers["Access-Control-Allow-Origin"] = "*"
  #   response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD"
  #   response.headers["Access-Control-Allow-Headers"] = "*"
  #   response.headers["Access-Control-Expose-Headers"] = "Authorization"
  #   response.headers["Access-Control-Max-Age"] = "7200"
  #   head :ok
  # end

  def health_check
    render json: { status: "API is running" }, status: :ok
  end

  protected

  def set_default_accept
    request.format = :json if request.headers["Accept"] =~ /application\/json|text\/plain|\*\/\*/
  end

  # This method tells Devise which custom parameters to allow for sign_up and account_update.
  # def configure_permitted_parameters
  #   # For the :sign_up action (POST /api/v1/signup)
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [
  #     :first_name, :middle_name, :last_name, :date_of_birth, :mobile_no,
  #     :address_line_01, :address_line_02, :city, :zip_code, :country_id
  #   ])

  #   # You can also permit parameters for updating an account (:account_update)
  #   # devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, ...])
  # end
end
