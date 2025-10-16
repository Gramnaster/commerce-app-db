FactoryBot.define do
  factory :admin_detail do
    admin_user { nil }
    first_name { "MyString" }
    middle_name { "MyString" }
    last_name { "MyString" }
    dob { "2025-10-16" }
  end
end
