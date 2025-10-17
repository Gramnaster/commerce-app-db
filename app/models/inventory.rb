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
  return if sku.present?

  loop do
    # Get related IDs and encode as base36 (upcase for letters)
    category_code = product.product_category_id.to_s(36).upcase.rjust(3, "0")
    producer_code = product.producer_id.to_s(36).upcase.rjust(3, "0")
    product_code  = product_id.to_s(36).upcase.rjust(3, "0")
    random_code   = SecureRandom.random_number(1000).to_s.rjust(3, "0")

    # Format: XXXYYYZZZ999 (letters+digits)
    self.sku = "#{category_code}#{producer_code}#{product_code}#{random_code}"

    break unless Inventory.exists?(sku: sku)
  end
end

  def company_site_must_be_warehouse
    if company_site && company_site.site_type != "warehouse"
      errors.add(:company_site, "must be a warehouse site, not management site")
    end
  end
end
