class CreateShoppingCartItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_cart_items do |t|
      t.references :shopping_cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :qty, null: false, default: 0

      t.timestamps
    end
  end
end
