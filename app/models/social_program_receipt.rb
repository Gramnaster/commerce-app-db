class SocialProgramReceipt < ApplicationRecord
  belongs_to :social_program
  belongs_to :receipt

  validates :social_program_id, presence: true
  validates :receipt_id, presence: true
end
