class ShoppingCartItem < ApplicationRecord
  belongs_to :shopping_cart
  belongs_to :product

  validates :qty, presence: true, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :shopping_cart_id, message: "already exists in cart" }
end
