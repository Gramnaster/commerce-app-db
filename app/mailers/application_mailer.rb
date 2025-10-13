class ApplicationMailer < ActionMailer::Base
  default from: ENV["GMAIL_USERNAME"] || "noreply@commerce.com"
  layout "mailer"
end
