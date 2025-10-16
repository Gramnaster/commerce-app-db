class CreateWarehouseOrders < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE TYPE product_status AS ENUM ('storage', 'progress', 'delivered');
    SQL
    create_table :warehouse_orders do |t|
      t.references :company_site, null: false, foreign_key: true
      t.references :inventory, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :qty
      t.column :product_status, :product_status, null: false

      t.timestamps
    end
  end
  def down
    drop_table :warehouse_orders

    execute <<-SQL
      DROP TYPE product_status;
    SQL
  end
end
