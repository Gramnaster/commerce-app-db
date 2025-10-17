class UserCartOrder < ApplicationRecord
  belongs_to :shopping_cart_item
  belongs_to :user_address
end
