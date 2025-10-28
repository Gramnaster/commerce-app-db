class Address < ApplicationRecord
  belongs_to :country
  has_many :user_addresses, dependent: :destroy
  has_many :users, through: :user_addresses
  has_many :admin_addresses, dependent: :destroy
  has_many :admin_users, through: :admin_addresses
  has_many :producers, dependent: :destroy
  has_many :company_sites, dependent: :destroy

  validates :unit_no, :street_no, :barangay, :city, :zipcode, :country_id, presence: true
end
