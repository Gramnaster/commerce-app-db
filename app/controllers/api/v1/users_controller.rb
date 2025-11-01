class Api::V1::UsersController < Api::V1::BaseController
  include Paginatable

  # Skip base controller authentication for admin users
  skip_before_action :authenticate_user!, if: :admin_authenticated?

  before_action :authenticate_user_or_admin!
  before_action :set_user, only: [ :show, :update, :destroy ]
  before_action :authorize_user!, only: [ :show, :update ]

  def index
    # Only management admins can view all users
    unless current_admin_user&.management?
      return render json: { error: "Unauthorized. Management role required." }, status: :forbidden
    end

    users = User.includes(:user_detail, :phones, { user_addresses: :address }, :user_payment_methods).all

    result = paginate_collection(users, default_per_page: 20)
    @users = result[:collection]
    @pagination = result[:pagination]

    render :index
  end

  def show
  end

  # GET /api/v1/users/:id/full_details
  # Returns complete user information including receipts, cart orders, and warehouse orders
  # Only accessible by management admin users
  def full_details
    # Only management admins can access full details
    unless current_admin_user&.management?
      return render json: { error: "Unauthorized. Management role required." }, status: :forbidden
    end

    # Eager load all associations to avoid N+1 queries
    @user = User.includes(
      :user_detail,
      :phones,
      { user_addresses: { address: :country } },
      :user_payment_methods,
      { receipts: [ :user_cart_order, :social_program_receipts ] },
      { shopping_cart: { user_cart_orders: [ { warehouse_orders: [ :inventory, :company_site ] }, :social_program ] } }
    ).find(params[:id])

    render :full_details
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

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

  # Check if admin is authenticated (used to skip user authentication)
  def admin_authenticated?
    token = request.headers["Authorization"]&.split(" ")&.last
    return false unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      payload = decoded_token.first
      payload["scp"] == "admin_user"
    rescue JWT::DecodeError
      false
    end
  end

  # Authenticate either user or admin
  def authenticate_user_or_admin!
    token = request.headers["Authorization"]&.split(" ")&.last
    return render json: { error: "Missing authentication token" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"], true, { algorithm: "HS256" })
      payload = decoded_token.first

      if payload["scp"] == "admin_user"
        # Admin user authentication
        @current_admin_user = AdminUser.find(payload["sub"])

        # Verify JTI for admin users
        unless @current_admin_user.jti == payload["jti"]
          render json: { error: "Token has been revoked" }, status: :unauthorized
        end
      elsif payload["scp"] == "user"
        # Regular user authentication - let Devise handle it
        authenticate_user!
      else
        render json: { error: "Invalid token scope" }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      render json: { error: "Invalid or expired token: #{e.message}" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
    end
  end

  # Helper to get current admin user
  def current_admin_user
    @current_admin_user
  end

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
  @user = User.includes(:user_detail, :phones, { user_addresses: :address }, :user_payment_methods).find(params[:id])
  end

  # def set_user
  #   @user = User.find(params[:id])
  # end

  def authorize_user!
    # Management admins can view any user
    return if current_admin_user&.management?

    # Regular users can only view themselves
    unless current_user&.id == @user.id
      render json: { error: "Unauthorized" }, status: :forbidden
    end
  end

  def user_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      user_detail_attributes: [ :id, :first_name, :middle_name, :last_name, :dob, :_destroy ],
      phones_attributes: [ :id, :phone_no, :phone_type, :_destroy ],
      user_addresses_attributes: [
        :id, :is_default, :_destroy,
        address_attributes: [ :id, :unit_no, :street_no, :address_line1, :address_line2,
                            :barangay, :city, :region, :zipcode, :country_id ]
      ],
      user_payment_methods_attributes: [ :id, :balance, :payment_type, :_destroy ]
    )
  end
end
