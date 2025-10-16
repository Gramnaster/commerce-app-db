class CompanySite < ApplicationRecord
  belongs_to :address
  has_many :inventories, dependent: :destroy
  has_many :warehouse_orders, dependent: :destroy
  has_many :admin_users_company_sites, dependent: :destroy
  has_many :admin_users, through: :admin_users_company_sites
  has_many :products, through: :inventories

  enum :site_type, { warehouse: "warehouse", management: "management" }
end
