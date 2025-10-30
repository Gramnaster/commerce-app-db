class SocialProgram < ApplicationRecord
  belongs_to :address
  has_many :social_program_receipts, dependent: :destroy
  has_many :receipts, through: :social_program_receipts

  validates :title, presence: true, uniqueness: true
  validates :description, presence: true
  validates :address, presence: true

  accepts_nested_attributes_for :address, allow_destroy: false
end
