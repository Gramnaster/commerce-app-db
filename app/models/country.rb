class Country < ApplicationRecord
  has_many :address

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
end
