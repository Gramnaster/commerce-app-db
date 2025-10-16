class CreateAdminUsersCompanySites < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_users_company_sites do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.references :company_site, null: false, foreign_key: true

      t.timestamps
    end
  end
end
