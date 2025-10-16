class Api::V1::AdminUsersController < Api::V1::BaseController
  before_action :authenticate_admin_user!
  before_action :set_admin_user, only: [ :show, :update, :destroy ]
  before_action :authorize_admin_user!, only: [ :show, :update ]

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
                                      :addresses).find(params[:id])
  end

  def authorize_admin_user!
    unless current_admin_user.id == @admin_user.id
      render json: { error: "Unauthorized" }, status: :forbidden
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
