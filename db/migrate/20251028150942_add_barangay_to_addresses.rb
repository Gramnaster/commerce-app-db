class AddBarangayToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :barangay, :string

    # Set a default value for existing records
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE addresses SET barangay = 'Unknown' WHERE barangay IS NULL
        SQL
      end
    end

    # Now make it not null
    change_column_null :addresses, :barangay, false
  end
end
