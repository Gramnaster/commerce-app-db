FactoryBot.define do
  factory :receipt do
    user { nil }
    product { nil }
    user_cart_order { nil }
    total_cost { "9.99" }
  end
end
