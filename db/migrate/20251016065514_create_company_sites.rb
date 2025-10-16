class CreateCompanySites < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE TYPE site_type AS ENUM ('management', 'warehouse');
    SQL

    create_table :company_sites do |t|
      t.string :title, null: false
      t.references :address, null: false, foreign_key: true
      t.column :site_type, :site_type, default: 'warehouse', null: false

      t.timestamps
    end

    add_index :company_sites, :title, unique: true
    add_index :company_sites, :site_type
  end

  def down
    drop_table :company_sites

    execute <<-SQL
      DROP TYPE site_type
    SQL
  end
end
