class CreateSocialPrograms < ActiveRecord::Migration[8.1]
  def change
    create_table :social_programs do |t|
      t.string :title
      t.string :description
      t.references :address, foreign_key: true, null: false

      t.timestamps
    end
  end
end
