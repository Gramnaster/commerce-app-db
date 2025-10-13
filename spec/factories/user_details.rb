FactoryBot.define do
  factory :user_detail do
    user_id { nil }
    first_name { "MyString" }
    middle_name { "MyString" }
    last_name { "MyString" }
    dob { "2025-10-13" }
  end
end
