FactoryBot.define do
  factory :inventory do
    company_site { nil }
    product { nil }
    SKU { "MyString" }
    qty_in_stock { 1 }
  end
end
