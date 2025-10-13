class CreatePhones < ActiveRecord::Migration[8.0]
  def up
    # This tells Rails what to integrate for migration
    execute <<-SQL
      CREATE TYPE phone_type AS ENUM ('mobile', 'home', 'work');
    SQL

    create_table :phones do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :phone_no, null: false, default: ""
      t.column :phone_type, :phone_type, null: false, default: "mobile"

      t.timestamps
    end

    add_index :phones, :phone_type
  end

  def down
    # This tells Rails how to reverse the migration.
    drop_table :phones

    execute <<-SQL
      DROP TYPE phone_type;
    SQL
  end
end
