class ChangePromotionsNullableOnProducts < ActiveRecord::Migration[8.0]
  def change
    rename_column :products, :promotions_id, :promotion_id
    change_column_null :products, :promotion_id, true
  end
end
