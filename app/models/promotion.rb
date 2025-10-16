class Promotion < ApplicationRecord
  has_many :products, dependent: :nullify
  has_many :promotions_categories, dependent: :destroy
  has_many :product_categories, through: :promotions_categories
end
