class PtbScrapperMigration < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :name
      t.datetime :launch_date
      t.integer :meta_score
      t.text :positive_reviews
      t.text :negative_reviews
      t.float :price
      t.float :sale_price
      t.datetime :reviews_updated_at
      t.datetime :game_list_updated_at
      t.datetime :game_updated_at
      t.text :categories
    end

    create_table :prices do |t|
      t.datetime :date
      t.float :price
      t.float :sale_price
      t.integer :game_id
    end

    add_index :prices, :game_id
  end
end
