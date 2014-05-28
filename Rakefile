require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks

desc 'Test'
task :test do
  exec 'guard --force_polling'
end

namespace :scrap do
  desc 'Scrap the games list to get new games, prices, and stuff'
  task :all_games do
    require_relative './init'
    scrapper = ScrappingOverlord.new
    scrapper.scrap_games(true)
  end

  desc 'Scrap each game to get the categories and other stuff'
  task :each_game do
    require_relative './init'
    scrapper = ScrappingOverlord.new
    scrapper.scrap_categories(true)
  end

  desc 'Scrap the reviews for each game'
  task :reviews do
    require_relative './init'
    scrapper = ScrappingOverlord.new
    scrapper.scrap_reviews(true)
  end
end

task default: :test