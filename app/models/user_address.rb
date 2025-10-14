class UserAddress < ApplicationRecord
  belongs_to :user
  belongs_to :address

  accepts_nested_attributes_for :address

  before_save :ensure_default

  private

  # Ensures that the a user address is the default...
  # only if the default is changed
  def ensure_default
    if is_default_changed? && is_default?
      UserAddress.where(user_id: user_id)
                  .where.not(id: id)
                  .update_all(is_default: false)
    end
  end
end
