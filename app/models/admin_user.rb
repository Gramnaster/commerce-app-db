class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :admin_detail, dependent: :destroy
  has_many :admin_phones, dependent: :destroy
  has_many :admin_addresses, dependent: :destroy
  has_many :addresses, through: :admin_addresses
  has_many :admin_users_company_sites, dependent: :destroy
  has_many :company_sites, through: :admin_users_company_sites
end
