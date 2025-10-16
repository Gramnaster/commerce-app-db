class Producer < ApplicationRecord
  belongs_to :address
  has_many :products, dependent: :destroy

  validates :title, presence: true, uniqueness: true
  validates :address, presence: true

  # Accept nested attributes for address to allow creating/updating address with producer
  accepts_nested_attributes_for :address, allow_destroy: false
end
