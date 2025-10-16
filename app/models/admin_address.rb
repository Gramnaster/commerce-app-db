class AdminAddress < ApplicationRecord
  belongs_to :admin_user
  belongs_to :address
end
