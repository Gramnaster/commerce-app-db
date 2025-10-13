class UserMailer < ApplicationMailer
  def customer_approval_notification(user)
    @user = user
    @app_name = "Commerce App"

    mail(
      to: @user.email,
      subject: "Your Account Has Been Verified!"
    )
  end

  def customer_rejection_notification(user)
    @user = user
    @app_name = "Commerce App"

    mail(
      to: @user.email,
      subject: "Update on Your Commerce Account Application"
    )
  end

  def signup_confirmation(user)
    @user = user
    @app_name = "Commerce App"

    mail(
      to: @user.email,
      subject: "Welcome to Commerce App - Please Confirm Your Email"
    )
  end

  def admin_new_customer_notification(user, admin_email = nil)
    @user = user
    @app_name = "Commerce App"
    @admin_email = admin_email || ENV["ADMIN_EMAIL"] || "admin@commerce.com"

    mail(
      to: @admin_email,
      subject: "New Trader Registration Pending Approval"
    )
  end
end
