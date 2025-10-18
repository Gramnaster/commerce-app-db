class AddUserCartOrderIdToWarehouseOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :warehouse_orders, :user_cart_order, null: false, foreign_key: true
  end
end
