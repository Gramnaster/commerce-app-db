class Inventory < ApplicationRecord
  belongs_to :company_site
  belongs_to :product
  has_many :warehouse_orders, dependent: :destroy

  # Validations
  validates :sku, presence: true, uniqueness: true
  validates :qty_in_stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :company_site, presence: true
  validates :product, presence: true
  validate :company_site_must_be_warehouse

  private

  def company_site_must_be_warehouse
    if company_site && company_site.site_type != "warehouse"
      errors.add(:company_site, "must be a warehouse type, not management type")
    end
  end
end
