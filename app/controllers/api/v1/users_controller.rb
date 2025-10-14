class Api::V1::UsersController < ApplicationController
  # include AdminAuthorization
  # before_action :require_admin, only: [ :index, :create, :update, :destroy, :update_status ]
  # before_action :set_user, only: [ :show, :update, :destroy, :update_status ]
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :update, :destroy ]
  before_action :authorize_user!, only: [ :update ]

  # def index
  #   @users = User.all.includes(:country, :wallet)
  # end

  # def show
  # end

  def create
    @user = User.new(user_params)
    @user.password = params[:password] if params[:password].present?
    @user.password_confirmation = params[:password_confirmation] if params[:password_confirmation].present?

    # Auto-confirm admin-created users
    @user.confirmed_at = Time.current

    if @user.save
      render :create, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @user.update(user_params)
      render :update
    else
      render json: { errors: @user.errors.full_messages  }, status: :unprocessable_content
    end
  end

  def destroy
    if @user.destroy
      render json: { message: "User deleted successfully" }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update_status
    old_status = @user.user_status

    if @user.update(user_status: params[:user_status])
      # Send appropriate email based on status change
      if old_status != @user.user_status && @user.trader?
        case @user.user_status
        when "approved"
          UserMailer.trader_approval_notification(@user).deliver_now
        when "rejected"
          UserMailer.trader_rejection_notification(@user).deliver_now
        end
      end

      render :update_status
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
    end
  end

  # def pending_traders
  #   @users = User.where(user_status: "pending", user_role: "trader").includes(:country, :wallet)
  #   render :index
  # end

  private

  # def set_user
  #   @user = User.find(params[:id])
  # rescue ActiveRecord::RecordNotFound
  #   render json: { error: "User not found" }, status: :not_found
  # end

  # def user_params
  #   params.require(:user).permit(
  #     :email, :password,
  #   )
  # end
  def set_user
    @user = User.includes(:user_detail, :phones, :user_addresses,
                          :addresses, :user_payment_methods).find(params[:id])
  end

  def authorize_user!
    unless current_user.id == @user.id || current_user.admin?
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  def user_params
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
end
