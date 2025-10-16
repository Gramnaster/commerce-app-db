FactoryBot.define do
  factory :warehouse_order do
    company_site { nil }
    inventory { nil }
    user { nil }
    qty { 1 }
  end
end
