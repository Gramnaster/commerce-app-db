class AddUserOrderIdToWareHouseOrder < ApplicationRecord
  belongs_to :user_cart_order
end
