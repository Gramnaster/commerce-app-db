class WarehouseOrder < ApplicationRecord
  belongs_to :company_site
  belongs_to :inventory
  belongs_to :user
  belongs_to :user_cart_order

  validates :qty, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :product_status, presence: true

  enum :product_status, { pending: "pending", shipped: "shipped", delivered: "delivered", cancelled: "cancelled" }
end
