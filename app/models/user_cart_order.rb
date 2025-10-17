class UserCartOrder < ApplicationRecord
  belongs_to :shopping_cart
  belongs_to :user_address
  has_many :warehouse_orders, dependent: :destroy

  # Validations
  validates :total_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :is_paid, inclusion: { in: [true, false] }
  validates :cart_status, presence: true

  # Enum for cart_status
  enum cart_status: { pending: "pending", approved: "approved", rejected: "rejected" }
end
