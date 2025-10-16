class Inventory < ApplicationRecord
  belongs_to :company_site
  belongs_to :product
  has_many :warehouse_orders, dependent: :destroy
end
