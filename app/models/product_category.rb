class ProductCategory < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :promotions_categories, foreign_key: :product_categories_id, dependent: :destroy
  has_many :promotions, through: :promotions_categories

  validates :title, presence: true, uniqueness: true
end
