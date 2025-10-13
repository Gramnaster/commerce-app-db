FactoryBot.define do
  factory :user_address do
    user_id { nil }
    address_id { nil }
    is_default { false }
  end
end
