class Address < ApplicationRecord
  belongs_to :country
  has_many :user_addresses, dependent: :destroy
  has_many :users, through: :user_addresses

  validates :unit_no, :street_no, :city, :zipcode, :country_id, presence: true
end
