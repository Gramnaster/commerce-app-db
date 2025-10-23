class ApplicationMailer < ActionMailer::Base
  default from: ENV["GMAIL_USERNAME"] || "noreply@commerce.com"
  layout "mailer"
  retry_on StandardError, attempts: 1

  def mail(headers = {}, &block)
    Rails.logger.debug "[ApplicationMailer] mail called: headers=#{headers.inspect}"
    super
  end
end
