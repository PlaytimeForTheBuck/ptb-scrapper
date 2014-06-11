task :environment do
  PtbScrapper.init
end

namespace :scrapper do
  desc 'Scrap the games list to get new games, prices, and stuff'
  task games_list: :environment do
    scrapper = PtbScrapper::ScrappingOverlord.new
    scrapper.scrap_games_list(true)
  end

  desc 'Scrap each game to get the categories and other stuff'
  task games: :environment  do
    scrapper = PtbScrapper::ScrappingOverlord.new
    scrapper.scrap_games(true)
  end

  desc 'Scrap the reviews for each game'
  task reviews: :environment  do
    scrapper = PtbScrapper::ScrappingOverlord.new
    scrapper.scrap_reviews(true)
  end

  desc 'Save summary'
  task summary: :environment  do
    scrapper = PtbScrapper::ScrappingOverlord.new
    scrapper.create_summary
  end

  namespace :expire do
    desc 'Expire games'
    task games: :environment do
      PtbScrapper::Models::GameAr.expire_games
    end
  end

  desc 'Create migration files'
  task :migrations do
    migration_name = Time.now.strftime('%Y%m%d%H%M%S') + '_ptb_scrapper_migration.rb'
    template_migration = File.join PtbScrapper.root, 'lib/ptb_scrapper/ptb_scrapper_migration.rb'
    destination_migration = File.join 'db/migrations', migration_name
    FileUtils.mkpath 'db/migrations'
    FileUtils.copy template_migration, destination_migration
  end
end