class Inventory < ApplicationRecord
  belongs_to :company_site
  belongs_to :product
end
