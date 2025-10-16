FactoryBot.define do
  factory :admin_address do
    admin_user { nil }
    address { nil }
    is_default { false }
  end
end
