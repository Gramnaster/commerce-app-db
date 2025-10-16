class Inventory < ApplicationRecord
  belongs_to :company_site
  belongs_to :product
  has_many :warehouse_orders, dependent: :destroy

  # Callbacks
  before_validation :generate_sku, on: :create

  # Validations
  validates :sku, presence: true, uniqueness: true
  validates :qty_in_stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :company_site, presence: true
  validates :product, presence: true
  validate :company_site_must_be_warehouse

  private

  def generate_sku
    # Only generate if SKU is not provided
    return if sku.present?

    loop do
      # Generate a 12-digit UPC-like code
      # Format: 3 digits (company_site) + 6 digits (product) + 3 digits (random)
      site_code = company_site_id.to_s.rjust(3, "0")
      product_code = product_id.to_s.rjust(6, "0")
      random_code = SecureRandom.random_number(1000).to_s.rjust(3, "0")

      self.sku = "#{site_code}#{product_code}#{random_code}"

      # Break if SKU is unique, otherwise regenerate
      break unless Inventory.exists?(sku: sku)
    end
  end

  def company_site_must_be_warehouse
    if company_site && company_site.site_type != "warehouse"
      errors.add(:company_site, "must be a warehouse type, not management type")
    end
  end
end
