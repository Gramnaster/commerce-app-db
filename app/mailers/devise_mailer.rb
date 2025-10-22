class DeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  default template_path: "devise/mailer" # to use the devise views

  def confirmation_instructions(record, token, opts = {})
    # Build frontend confirmation URL
    frontend_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/users/confirmation?confirmation_token=#{token}"
    opts[:confirmation_url] = frontend_url
    @confirmation_url = frontend_url
    super
  end
end
