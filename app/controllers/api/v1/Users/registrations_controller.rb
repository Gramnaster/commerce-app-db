# frozen_string_literal: true

class Api::V1::Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  #
  respond_to :json
  def create
    build_resource(sign_up_params)

    # Skip synchronous confirmation email (we'll queue it instead for faster response)
    resource.skip_confirmation_notification!

    resource.save
    if resource.persisted?
      # Send confirmation email asynchronously via SolidQueue
      if resource.class.devise_modules.include?(:confirmable)
        # Generate token and send email async
        resource.generate_confirmation_token! unless resource.confirmation_token
        Devise::Mailer.confirmation_instructions(resource, resource.confirmation_token).deliver_later
      end

      # TODO: Enable welcome email when ready
      # UserMailer.signup_confirmation(resource).deliver_later

      # TODO: Uncomment when user_role field is added and trader? method is implemented
      # if resource.trader?
      #   UserMailer.admin_new_customer_notification(resource).deliver_later
      # end

      # If the user was saved, let Rails render the view at:
      # app/views/api/v1/users/registrations/create.json.jbuilder
      # The JWT will be in the response headers automatically.
      render :create, status: :created
    else
      # If saving failed, render the errors as JSON.
      render json: {
        status: { message: "User couldn't be created. #{resource.errors.full_messages.to_sentence}" }
      }, status: :unprocessable_content
    end
  end

  respond_to :json
  def create
    build_resource(sign_up_params)

    # Skip Devise's automatic confirmation email (we'll send it async instead)
    resource.skip_confirmation_notification!

    resource.save
    if resource.persisted?
      # Send Devise confirmation instructions asynchronously if confirmable is enabled
      if resource.class.devise_modules.include?(:confirmable) && !resource.confirmed?
        resource.send_confirmation_instructions_async
      end

      # Send welcome email to user asynchronously
      # UserMailer.signup_confirmation(resource).deliver_later

      # Notify admin of new trader registration (only for traders) asynchronously
      # if resource.trader?
      # UserMailer.admin_new_trader_notification(resource).deliver_later
      # end

      # If the user was saved, let Rails render the view at:
      # app/views/api/v1/users/registrations/create.json.props
      # The JWT will be in the response headers automatically.
      render :create, status: :created
    else
      # If saving failed, render the errors as JSON.
      render json: {
        status: { message: "User couldn't be created. #{resource.errors.full_messages.to_sentence}" }
      }, status: :unprocessable_content
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      user_detail_attributes: [ :first_name, :middle_name, :last_name, :dob, :_destroy ],
      phones_attributes: [ :id, :phone_no, :phone_type, :_destroy ],
      user_address_attributes: [
        :id, :is_default, :_destroy,
        address_attributes: [ :id, :unit_no, :street_no, :address_line1, :address_line2,
                            :city, :region, :zipcode, :country_id ]
      ],
      user_payment_methods_attributes: [ :id, :balance, :payment_type, :_destroy ]
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
