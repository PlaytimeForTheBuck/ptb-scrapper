class AddFeaturesFlags < ActiveRecord::Migration
  def change
    add_column :games, :features_flags, :integer, null: false, default: 0
  end
end
