class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.string :message_id
      t.string :title
      t.text :body
      t.text :body_en
      t.integer :label, default: 0
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
