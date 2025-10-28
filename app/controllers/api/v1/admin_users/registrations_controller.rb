# frozen_string_literal: true

class Api::V1::AdminUsers::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  #
  respond_to :json

  def create
    build_resource(sign_up_params)

    resource.save
    if resource.persisted?
      # If the admin user was saved, let Rails render the view at:
      # app/views/api/v1/admin_users/registrations/create.json.props
      render :create, status: :created
    else
      # If saving failed, render the errors as JSON with detailed messages
      render json: {
        status: {
          code: 422,
          message: "Admin user couldn't be created."
        },
        errors: resource.errors.full_messages
      }, status: :unprocessable_content
    end
  rescue ActionController::ParameterMissing => e
    render json: {
      status: { code: 400, message: "Missing required parameters." },
      errors: [ e.message ]
    }, status: :bad_request
  end

  private

  def sign_up_params
    params.require(:admin_user).permit(
      :email, :password, :password_confirmation, :admin_role,
      admin_detail_attributes: [ :first_name, :middle_name, :last_name, :dob, :_destroy ],
      admin_phones_attributes: [ :id, :phone_no, :phone_type, :_destroy ],
      admin_addresses_attributes: [
        :id, :is_default, :_destroy,
        address_attributes: [ :id, :unit_no, :street_no, :address_line1, :address_line2,
                            :barangay, :city, :region, :zipcode, :country_id ]
      ]
    )
  end

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
