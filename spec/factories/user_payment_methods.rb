FactoryBot.define do
  factory :user_payment_method do
    user_id { nil }
    balance { "9.99" }
  end
end
