class AddIsVerifiedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_verified, :boolean, default: false
  end
end
