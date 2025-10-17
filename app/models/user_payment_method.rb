class UserPaymentMethod < ApplicationRecord
  belongs_to :user

  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Deposit funds into the payment method
  def deposit(amount)
    return { success: false, error: "Amount must be positive" } if amount <= 0

    self.balance += amount
    if save
      { success: true, new_balance: balance }
    else
      { success: false, error: errors.full_messages.join(", ") }
    end
  end

  # Withdraw funds from the payment method
  def withdraw(amount)
    return { success: false, error: "Amount must be positive" } if amount <= 0
    return { success: false, error: "Insufficient funds" } if balance < amount

    self.balance -= amount
    if save
      { success: true, new_balance: balance }
    else
      { success: false, error: errors.full_messages.join(", ") }
    end
  end

  # Check if user has sufficient balance
  def sufficient_balance?(amount)
    balance >= amount
  end
end
