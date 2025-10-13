class ChangeJtiNullableOnUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :jti, true
  end
end
