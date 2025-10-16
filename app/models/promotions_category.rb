class PromotionsCategory < ApplicationRecord
  belongs_to :product_category, foreign_key: :product_categories_id
  belongs_to :promotion, foreign_key: :promotions_id

  validates :product_categories_id, presence: true
  validates :promotions_id, presence: true
  validates :product_categories_id, uniqueness: { scope: :promotions_id, message: "has already been associated with this promotion" }
end
