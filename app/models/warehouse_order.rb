class WarehouseOrder < ApplicationRecord
  belongs_to :company_site
  belongs_to :inventory
  belongs_to :user

  enum :product_status, { pending: "pending", shipped: "shipped", delivered: "delivered", cancelled: "cancelled" }
end
