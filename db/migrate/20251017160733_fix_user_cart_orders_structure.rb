class FixUserCartOrdersStructure < ActiveRecord::Migration[8.0]
  def change
    # Remove the shopping_cart_item reference (wrong design)
    remove_reference :user_cart_orders, :shopping_cart_item, foreign_key: true
    
    # Add shopping_cart reference instead (one order per cart)
    add_reference :user_cart_orders, :shopping_cart, null: false, foreign_key: true
    
    # Add total_cost to track order value
    add_column :user_cart_orders, :total_cost, :decimal, precision: 10, scale: 2, null: false, default: 0.0
  end
end
