class RemoveSteamAppIdToUseJustTheId < ActiveRecord::Migration
  def up
    remove_column :games, :steam_app_id
  end

  def down
    add_column :games, :steam_app_id, :integer
  end
end
