class CreateUserAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :user_addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end
  end
end
