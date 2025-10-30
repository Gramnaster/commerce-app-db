class Receipt < ApplicationRecord
  belongs_to :user
  belongs_to :user_cart_order, optional: true
  has_many :social_program_receipts, dependent: :destroy
  has_many :social_programs, through: :social_program_receipts

  # Validations
  validates :transaction_type, presence: true, inclusion: { in: %w[purchase deposit withdraw donation] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :balance_before, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :balance_after, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Enum for transaction types
  enum :transaction_type, {
    purchase: "purchase",
    deposit: "deposit",
    withdraw: "withdraw",
    donation: "donation"
  }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :purchases, -> { where(transaction_type: "purchase") }
  scope :deposits, -> { where(transaction_type: "deposit") }
  scope :withdrawals, -> { where(transaction_type: "withdraw") }
  scope :donations, -> { where(transaction_type: "donation") }
end
