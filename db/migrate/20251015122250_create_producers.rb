class CreateProducers < ActiveRecord::Migration[8.0]
  def change
    create_table :producers do |t|
      t.string :title
      t.references :address, null: false, foreign_key: true

      t.timestamps
    end
  end
end
