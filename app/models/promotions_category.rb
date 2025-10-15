class PromotionsCategory < ApplicationRecord
  belongs_to :product_categories
  belongs_to :promotions
end
