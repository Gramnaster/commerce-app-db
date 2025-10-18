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
    discount = applicable_discount
    return price if discount.zero?

    discounted = price - discount
    discounted < 0 ? 0 : discounted
  end

  # Get the applicable discount amount (from direct promotion or category promotion)
  def applicable_discount
    # Direct product promotion takes precedence
    return promotion.discount_amount if promotion.present?

    # Check for category promotions
    category_promotion = product_category.promotions.first
    return category_promotion.discount_amount if category_promotion.present?

    0
  end

  # Check if product has any promotion
  def has_promotion?
    promotion.present? || product_category.promotions.any?
  end
end
