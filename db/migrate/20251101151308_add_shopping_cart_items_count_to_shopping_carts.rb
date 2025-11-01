class AddShoppingCartItemsCountToShoppingCarts < ActiveRecord::Migration[8.1]
  def change
    add_column :shopping_carts, :shopping_cart_items_count, :integer, default: 0, null: false

    # Reset counter cache for existing records
    reversible do |dir|
      dir.up do
        ShoppingCart.find_each do |cart|
          cart.update_column(:shopping_cart_items_count, cart.shopping_cart_items.count)
        end
      end
    end
  end
end
