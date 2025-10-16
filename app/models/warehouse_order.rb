class WarehouseOrder < ApplicationRecord
  belongs_to :company_site
  belongs_to :inventory
  belongs_to :user
end
