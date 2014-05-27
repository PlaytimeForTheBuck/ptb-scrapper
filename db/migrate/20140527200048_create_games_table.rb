class CreateGamesTable < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :name
      t.integer :steam_app_id
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
  end
end
