class PromotionsCategory < ApplicationRecord
  belongs_to :product_category, foreign_key: :product_categories_id
  belongs_to :promotion, foreign_key: :promotions_id
end
