class CreateUserDetails < ActiveRecord::Migration[8.0]
  def change
    create_table :user_details do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.date :dob, null: false

      t.timestamps
    end
  end
end
