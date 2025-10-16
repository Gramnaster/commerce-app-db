class AdminUsersCompanySite < ApplicationRecord
  belongs_to :admin_user
  belongs_to :company_site
end
