class Product < ApplicationRecord
  belongs_to :product_category
  belongs_to :producer
  belongs_to :promotion, optional: true
  has_many :shopping_cart_items, dependent: :destroy
  has_many :shopping_carts, through: :shopping_cart_items
  has_many :inventories, dependent: :destroy
  has_many :company_sites, through: :inventories

  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_category, presence: true
  validates :producer, presence: true
end
