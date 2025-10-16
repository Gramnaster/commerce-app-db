class CreateAdminAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_addresses do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end
  end
end
