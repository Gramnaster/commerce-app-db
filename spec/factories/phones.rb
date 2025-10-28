FactoryBot.define do
  factory :phone do
    phone_no { "+639171234567" }
    phone_type { "mobile" }
    user { nil }
  end
end
