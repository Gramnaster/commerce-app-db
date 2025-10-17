FactoryBot.define do
  factory :user_cart_order do
    shopping_cart_item { nil }
    user_address { nil }
    is_paid { false }
  end
end
