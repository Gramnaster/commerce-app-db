class CreateInventories < ActiveRecord::Migration[8.0]
  def change
    create_table :inventories do |t|
      t.references :company_site, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :sku, null: false
      t.integer :qty_in_stock

      t.timestamps
    end

    add_index :inventories, :sku, unique: true
  end
end
