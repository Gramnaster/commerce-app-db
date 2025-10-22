class ApplicationMailer < ActionMailer::Base
  default from: ENV["GMAIL_USERNAME"] || "noreply@commerce.com"
  layout "mailer"

  def mail(headers = {}, &block)
    Rails.logger.debug "[ApplicationMailer] mail called: headers=#{headers.inspect}"
    super
  end
end
