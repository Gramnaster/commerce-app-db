class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :title
      t.references :product_category, null: false, foreign_key: true
      t.references :producer, null: false, foreign_key: true
      t.string :description
      t.decimal :price, precision: 15, scale: 2
      t.references :promotions, null: false, foreign_key: true
      t.string :product_image_url

      t.timestamps
    end
  end
end
