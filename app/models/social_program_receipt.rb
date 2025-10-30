class SocialProgramReceipt < ApplicationRecord
  belongs_to :social_programs, foreign_key: :social_programs_id
  belongs_to :receipts, foreign_key: :receipts_id

  validates :social_programs_id, presence: true
  validates :receipts_id, presence: true
end
