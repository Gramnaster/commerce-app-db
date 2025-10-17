class FixUserCartOrdersStructure < ActiveRecord::Migration[8.0]
  def change
    # Remove the shopping_cart_item reference (wrong design)
    remove_reference :user_cart_orders, :shopping_cart_item, foreign_key: true

    # Add shopping_cart reference (temporarily nullable to populate data)
    add_reference :user_cart_orders, :shopping_cart, null: true, foreign_key: true

    # Populate shopping_cart_id for existing records
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE user_cart_orders
          SET shopping_cart_id = shopping_carts.id
          FROM user_addresses, shopping_carts
          WHERE user_cart_orders.user_address_id = user_addresses.id
          AND user_addresses.user_id = shopping_carts.user_id
        SQL
      end
    end

    # Now make it not null
    change_column_null :user_cart_orders, :shopping_cart_id, false

    # Add total_cost to track order value
    add_column :user_cart_orders, :total_cost, :decimal, precision: 10, scale: 2, null: false, default: 0.0
  end
end
