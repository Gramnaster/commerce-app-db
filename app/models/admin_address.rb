class AdminAddress < ApplicationRecord
  belongs_to :admin_user
  belongs_to :address

  accepts_nested_attributes_for :address

  before_save :ensure_default

  private

  # Ensures that an admin address is the default...
  # only if the default is changed
  def ensure_default
    if is_default_changed? && is_default?
      AdminAddress.where(admin_user_id: admin_user_id)
                   .where.not(id: id)
                   .update_all(is_default: false)
    end
  end
end
