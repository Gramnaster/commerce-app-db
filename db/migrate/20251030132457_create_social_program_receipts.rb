class CreateSocialProgramReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :social_program_receipts do |t|
      t.references :social_program, null: false, foreign_key: true
      t.references :receipt, null: false, foreign_key: true

      t.timestamps
    end
  end
end
