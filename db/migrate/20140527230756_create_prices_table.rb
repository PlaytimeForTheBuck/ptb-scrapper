class CreatePricesTable < ActiveRecord::Migration
  def change
    create_table :prices do |t|
      t.datetime :date
      t.float :price
      t.float :sale_price
      t.integer :game_id
    end

    add_index :prices, :game_id
  end
end
