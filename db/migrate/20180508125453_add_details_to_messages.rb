class AddDetailsToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :date, :datetime
    add_column :messages, :uptake_time, :datetime
  end
end
