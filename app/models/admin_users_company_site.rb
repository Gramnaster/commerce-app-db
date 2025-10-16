class AdminUsersCompanySite < ApplicationRecord
  belongs_to :admin
  belongs_to :company_site
end
