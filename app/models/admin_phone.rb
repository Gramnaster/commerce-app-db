class AdminPhone < ApplicationRecord
  belongs_to :admin_user

  enum :phone_type, { mobile: "mobile", home: "home", work: "work" }
end
