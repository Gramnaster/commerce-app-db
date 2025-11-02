class RefactorUserCartOrdersAddressStructure < ActiveRecord::Migration[8.1]
  def up
    # Add new columns (nullable first for data migration)
    add_column :user_cart_orders, :address_id, :bigint
    add_column :user_cart_orders, :user_id, :bigint

    # Migrate existing data
    # Copy address_id and user_id from user_addresses table
    execute <<-SQL
      UPDATE user_cart_orders
      SET#{' '}
        address_id = user_addresses.address_id,
        user_id = user_addresses.user_id
      FROM user_addresses
      WHERE user_cart_orders.user_address_id = user_addresses.id
    SQL

    # Verify all records were migrated
    unmigrated_count = execute("SELECT COUNT(*) FROM user_cart_orders WHERE address_id IS NULL OR user_id IS NULL").first["count"].to_i
    if unmigrated_count > 0
      raise "Migration failed: #{unmigrated_count} orders could not be migrated"
    end

    # Make columns NOT NULL
    change_column_null :user_cart_orders, :address_id, false
    change_column_null :user_cart_orders, :user_id, false

    # Add indices for better query performance
    add_index :user_cart_orders, :address_id
    add_index :user_cart_orders, :user_id

    # Add foreign key constraints
    add_foreign_key :user_cart_orders, :addresses, column: :address_id
    add_foreign_key :user_cart_orders, :users, column: :user_id

    # Remove old column and its constraints
    remove_foreign_key :user_cart_orders, :user_addresses
    remove_index :user_cart_orders, :user_address_id
    remove_column :user_cart_orders, :user_address_id
  end

  def down
    # Rollback: restore original structure
    add_column :user_cart_orders, :user_address_id, :bigint

    # Try to restore user_address_id by finding matching user_addresses
    # This may fail if user_addresses records were deleted
    execute <<-SQL
      UPDATE user_cart_orders
      SET user_address_id = (
        SELECT id#{' '}
        FROM user_addresses#{' '}
        WHERE user_addresses.user_id = user_cart_orders.user_id
          AND user_addresses.address_id = user_cart_orders.address_id
        LIMIT 1
      )
    SQL

    # Make NOT NULL
    change_column_null :user_cart_orders, :user_address_id, false

    # Restore index and FK
    add_index :user_cart_orders, :user_address_id
    add_foreign_key :user_cart_orders, :user_addresses

    # Remove new columns
    remove_foreign_key :user_cart_orders, :addresses
    remove_foreign_key :user_cart_orders, :users
    remove_index :user_cart_orders, :address_id
    remove_index :user_cart_orders, :user_id
    remove_column :user_cart_orders, :address_id
    remove_column :user_cart_orders, :user_id
  end
end
