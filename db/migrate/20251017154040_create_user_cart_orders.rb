class CreateUserCartOrders < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE TYPE cart_status AS ENUM ('rejected', 'pending', 'approved');
    SQL
    create_table :user_cart_orders do |t|
      t.references :shopping_cart_item, null: false, foreign_key: true
      t.references :user_address, null: false, foreign_key: true
      t.boolean :is_paid, null: false, default: false
      t.column :cart_status, :cart_status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :user_cart_orders, :cart_status
  end

  def down
    drop_table :user_cart_orders

    execute <<-SQL
      DROP TYPE cart_status;
    SQL
  end
end
