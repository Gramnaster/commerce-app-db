class CreateAdminPhones < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_phones do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.integer :phone_no, null: false, default: ""
      t.column :phone_type, :phone_type, null: false, default: "mobile"

      t.timestamps
    end

    add_index :admin_phones, :phone_type
  end
end
