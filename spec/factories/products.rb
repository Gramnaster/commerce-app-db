FactoryBot.define do
  factory :product do
    title { "MyString" }
    product_category { nil }
    producer { nil }
    description { "MyString" }
    price { "9.99" }
    promotions { nil }
    product_image_url { "MyString" }
  end
end
