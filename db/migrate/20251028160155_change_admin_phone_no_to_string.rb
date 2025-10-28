class ChangeAdminPhoneNoToString < ActiveRecord::Migration[8.1]
  def up
    # Change phone_no from integer to string for admin_phones table
    change_column :admin_phones, :phone_no, :string, null: false, default: ""
  end

  def down
    # Revert back to integer (data loss may occur if phone numbers have non-numeric characters)
    change_column :admin_phones, :phone_no, :integer, null: false, default: ""
  end
end
