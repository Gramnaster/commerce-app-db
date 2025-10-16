class Promotion < ApplicationRecord
  has_many :products, dependent: :nullify
  has_many :promotions_categories, dependent: :destroy
  has_many :product_categories, through: :promotions_categories

  validates :discount_amount, presence: true, numericality: { greater_than: 0 }
end
