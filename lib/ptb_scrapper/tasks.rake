task :environment do
  PtbScrapper.init
end

namespace :scrap do
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
end