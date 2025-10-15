class Product < ApplicationRecord
  belongs_to :product_category
  belongs_to :producer
  belongs_to :promotions
end
