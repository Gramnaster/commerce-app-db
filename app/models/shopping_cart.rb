class ShoppingCart < ApplicationRecord
  belongs_to :user
  has_many :shopping_cart_items, dependent: :destroy
  has_many :products, through: :shopping_cart_items
  has_many :user_cart_orders, dependent: :destroy
end
