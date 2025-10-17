class UserPaymentMethod < ApplicationRecord
  belongs_to :user

  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Deposit funds into the payment method
  def deposit(amount, description: nil)
    return { success: false, error: "Amount must be positive" } if amount <= 0

    balance_before = self.balance
    self.balance += amount
    
    if save
      # Create receipt for deposit
      Receipt.create!(
        user: user,
        transaction_type: "deposit",
        amount: amount,
        balance_before: balance_before,
        balance_after: self.balance,
        description: description || "Deposit to account"
      )
      
      { success: true, new_balance: balance }
    else
      { success: false, error: errors.full_messages.join(", ") }
    end
  end

  # Withdraw funds from the payment method
  def withdraw(amount, description: nil)
    return { success: false, error: "Amount must be positive" } if amount <= 0
    return { success: false, error: "Insufficient funds" } if balance < amount

    balance_before = self.balance
    self.balance -= amount
    
    if save
      # Create receipt for withdrawal
      Receipt.create!(
        user: user,
        transaction_type: "withdraw",
        amount: amount,
        balance_before: balance_before,
        balance_after: self.balance,
        description: description || "Withdrawal from account"
      )
      
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
