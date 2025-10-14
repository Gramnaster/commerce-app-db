class Phone < ApplicationRecord
  belongs_to :user

  enum phone_type: { mobile: "mobile", home: "home", work: "work" }
end
