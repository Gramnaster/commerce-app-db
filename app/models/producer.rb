class Producer < ApplicationRecord
  belongs_to :address
  has_many :products, dependent: :destroy
end
