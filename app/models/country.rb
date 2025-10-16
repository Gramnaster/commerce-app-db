class Country < ApplicationRecord
  has_many :addresses, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
end
