class DeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  default template_path: "devise/mailer" # to use the devise views

  def confirmation_instructions(record, token, opts = {})
    Rails.logger.debug "[DeviseMailer] === confirmation_instructions called ==="
    Rails.logger.debug "[DeviseMailer] record: #{record.inspect}"
    Rails.logger.debug "[DeviseMailer] token: #{token.inspect}"
    Rails.logger.debug "[DeviseMailer] opts (before): #{opts.inspect}"
    frontend_url = "#{ENV['FRONTEND_URL']}/users/confirmation?confirmation_token=#{token}"
    Rails.logger.debug "[DeviseMailer] ENV['FRONTEND_URL']: #{ENV['FRONTEND_URL'].inspect}"
    Rails.logger.debug "[DeviseMailer] frontend_url: #{frontend_url.inspect}"
    @confirmation_url = frontend_url
    @email = record.email
    opts[:confirmation_url] = frontend_url
    Rails.logger.debug "[DeviseMailer] opts (after): #{opts.inspect}"
    Rails.logger.debug "[DeviseMailer] @confirmation_url: #{@confirmation_url.inspect}"
    Rails.logger.debug "[DeviseMailer] @email: #{@email.inspect}"
    result = super
    Rails.logger.debug "[DeviseMailer] === confirmation_instructions finished ==="
    result
  end
end
