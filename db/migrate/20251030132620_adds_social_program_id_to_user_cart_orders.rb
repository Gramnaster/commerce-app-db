class AddsSocialProgramIdToUserCartOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :user_cart_orders, :social_program, foreign_key: true
  end
end
