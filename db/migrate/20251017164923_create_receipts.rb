class CreateReceipts < ActiveRecord::Migration[8.0]
  def change
    create_table :receipts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :user_cart_order, null: true, foreign_key: true
      t.string :transaction_type, null: false # 'purchase', 'deposit', 'withdraw'
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.decimal :balance_before, precision: 15, scale: 2, null: false
      t.decimal :balance_after, precision: 15, scale: 2, null: false
      t.text :description

      t.timestamps
    end

    # Add indexes (with if_not_exists to avoid duplication issues)
    add_index :receipts, :user_id, if_not_exists: true
    add_index :receipts, :transaction_type, if_not_exists: true
    add_index :receipts, :created_at, if_not_exists: true
  end
end
