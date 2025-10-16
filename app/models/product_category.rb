class ProductCategory < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :promotions_categories, dependent: :destroy
  has_many :promotions, through: :promotions_categories
end
