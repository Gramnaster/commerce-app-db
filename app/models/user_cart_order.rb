class UserCartOrder < ApplicationRecord
  belongs_to :shopping_cart
  belongs_to :address
  belongs_to :user
  belongs_to :social_program, optional: true
  has_many :warehouse_orders, dependent: :destroy

  # Validations
  validates :total_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :is_paid, inclusion: { in: [ true, false ] }
  validates :cart_status, presence: true

  # Enum for cart_status - use hash syntax for Rails 8.0
  enum :cart_status, { pending: "pending", approved: "approved", rejected: "rejected" }

  # Callback to create social program donation tracking after order is created
  after_create :create_social_program_donation, if: :social_program_id?

  private

  def create_social_program_donation
    # Calculate 8% of total cost for social program donation
    donation_amount = (total_cost * 0.08).round(2)

    # Get the user from shopping_cart
    user = shopping_cart.user

    # Create a receipt for the donation
    donation_receipt = Receipt.create!(
      user: user,
      user_cart_order: self,
      transaction_type: "donation",
      amount: donation_amount,
      balance_before: 0, # Donation doesn't affect user balance
      balance_after: 0,
      description: "8% donation to #{social_program.title} from Order ##{id}"
    )

    # Link the donation receipt to the social program
    SocialProgramReceipt.create!(
      social_program_id: social_program_id,
      receipt_id: donation_receipt.id
    )

    Rails.logger.info("[UserCartOrder] Created donation of #{donation_amount} to social program ##{social_program_id} for order ##{id}")
  rescue StandardError => e
    Rails.logger.error("[UserCartOrder] Failed to create social program donation for order ##{id}: #{e.message}")
    # Don't fail the order if donation tracking fails
  end
end
