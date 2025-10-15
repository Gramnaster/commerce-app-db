class CreatePromotionsCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :promotions_categories do |t|
      t.references :product_categories, null: false, foreign_key: true
      t.references :promotions, null: false, foreign_key: true

      t.timestamps
    end
  end
end
