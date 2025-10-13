class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :timeoutable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # Prevent unconfirmed users from signing in
  # def active_for_authentication?
  #   super && confirmed?
  # end

  # Custom message for unconfirmed users
  # def inactive_message
  #   confirmed? ? super : :unconfirmed
  # end
end
