class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :timeoutable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  validates :password_confirmation, presence: true

  has_one :user_detailm, dependent: :destroy
  has_many :user_addresses, dependent: :destroy
  has_many :addresses, through: :user_addresses
  has_many :phones, dependent: :destroy
  has_many :user_payment_methods, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :user_detail

  accepts_nested_attributes_for :phones

  accepts_nested_attributes_for :user_addresses

  accepts_nested_attributes_for :user_payment_methods

  def send_confirmation_instructions_async
    generate_confirmation_token! unless @raw_confirmation_token
    opts = pending_reconfirmation? ? { to: unconfirmed_email } : {}
    # Queue the confirmation email as an ActiveJob instead of sending it immediately
    Devise::Mailer.confirmation_instructions(self, @raw_confirmation_token, opts).deliver_later
  end
end
