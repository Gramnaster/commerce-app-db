FactoryBot.define do
  factory :shopping_cart_item do
    shopping_cart { nil }
    product { nil }
    qty { "9.99" }
  end
end
