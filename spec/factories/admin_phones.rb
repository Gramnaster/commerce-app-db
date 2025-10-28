FactoryBot.define do
  factory :admin_phone do
    phone_no { "+1234567890" }
    phone_type { "mobile" }
    admin_user { nil }
  end
end
