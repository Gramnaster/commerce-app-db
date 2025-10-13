class CreateUserPaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :user_payment_methods do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :balance, precision: 15, scale: 2, null: false, default: 0.00
      t.string :payment_type

      t.timestamps
    end
  end
end
