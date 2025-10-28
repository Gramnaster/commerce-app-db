FactoryBot.define do
  factory :address do
    unit_no { "MyString" }
    street_no { "MyString" }
    address_line1 { "MyString" }
    address_line2 { "MyString" }
    barangay { "MyBarangay" }
    city { "MyString" }
    region { "MyString" }
    zipcode { "MyString" }
    country { nil }
  end
end
