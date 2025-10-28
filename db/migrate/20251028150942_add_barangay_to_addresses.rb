class AddBarangayToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :barangay, :string, null: false
  end
end
