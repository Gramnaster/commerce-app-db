class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :timeoutable,
         :jwt_authenticatable, jwt_revocation_strategy: self


  # Override Devise's send_confirmation_instructions to make it async
  def send_confirmation_instructions_async
    generate_confirmation_token! unless @raw_confirmation_token
    opts = pending_reconfirmation? ? { to: unconfirmed_email } : {}
    # Queue the confirmation email as an ActiveJob instead of sending it immediately
    Devise::Mailer.confirmation_instructions(self, @raw_confirmation_token, opts).deliver_later
  end
end
