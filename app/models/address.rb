class Address < ApplicationRecord
  belongs_to :country
  has_many :user_addresses, dependent: :destroy
  has_many :users, through: :user_addresses
  has_many :admin_addresses, dependent: :destroy
  has_many :admin_users, through: :admin_addresses
  has_many :producers, dependent: :destroy
  has_many :company_sites, dependent: :destroy

  validates :unit_no, :street_no, :barangay, :city, :zipcode, :country_id, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  # Check if address has been geocoded
  def geocoded?
    latitude.present? && longitude.present?
  end

  # Build full address string for geocoding
  def full_address
    [ unit_no, street_no, barangay, city, zipcode, country&.name ].compact.join(", ")
  end
end
