class CreatePromotions < ActiveRecord::Migration[8.0]
  def change
    create_table :promotions do |t|
      t.decimal :discount_amount, precision: 15, scale: 2

      t.timestamps
    end
  end
end
