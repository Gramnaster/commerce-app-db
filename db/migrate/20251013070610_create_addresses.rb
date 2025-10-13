class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.string :unit_no,              null: false
      t.string :street_no,            null: false
      t.string :address_line1
      t.string :address_line2
      t.string :city,                 null: false
      t.string :region
      t.string :zipcode,              null: false
      t.references :country, null: false, foreign_key: true

      t.timestamps
    end
  end
end
