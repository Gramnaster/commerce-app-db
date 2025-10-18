class Product < ApplicationRecord
  belongs_to :product_category
  belongs_to :producer
  belongs_to :promotion, optional: true
  has_many :shopping_cart_items, dependent: :destroy
  has_many :shopping_carts, through: :shopping_cart_items
  has_many :inventories, dependent: :destroy
  has_many :company_sites, through: :inventories

  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_category, presence: true
  validates :producer, presence: true

  # Calculate final price with promotion discount applied
  def final_price
    discount_percentage = applicable_discount_percentage
    return price if discount_percentage.zero?

    # Calculate discounted price
    discounted = price * (1 - discount_percentage / 100.0)
    discounted < 0 ? 0 : discounted.round(2)
  end

  # Get the applicable discount percentage (from direct promotion or category promotion)
  def applicable_discount_percentage
    # Direct product promotion takes precedence
    return promotion.discount_amount if promotion.present?

    # Check for category promotions
    category_promotion = product_category.promotions.first
    return category_promotion.discount_amount if category_promotion.present?

    0
  end

  # Get the actual discount amount in dollars
  def discount_amount_dollars
    price - final_price
  end

  # Check if product has any promotion
  def has_promotion?
    promotion.present? || product_category.promotions.any?
  end
end
