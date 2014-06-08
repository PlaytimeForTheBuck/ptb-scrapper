class CreateOsFlags < ActiveRecord::Migration
  def change
    add_column :games, :os_flags, :integer, null: false, default: 0
  end
end
