require 'fileutils'

class ScrappingOverlord
  def initialize
    file_name = Time.now.strftime '%Y-%m-%d.%H-%M-%S.json'
    file_path = "db/#{file_name}"

    FileUtils.mkdir 'db' if not File.directory? 'db'

    last_file = Dir.glob('db/*').last
    if last_file
      FileUtils.cp last_file, file_path
    else
      FileUtils.touch file_path
    end

    file = File.open file_path, 'a+'
    Game.set_file file
  end

  def scrap_games
    games = Game.all
    scrapper = GamesScrapper.new games

    puts "Scrapping games: #{games.size} are the current games!"
    puts '============================================'

    scrapper.scrap do |page_games|
      puts "#{page_games.size} games in this page"
    end
  end

  def scrap_reviews
    games = Game.get_for_reviews_updating
    scrapper = ReviewsScrapper.new games

    puts "Scrapping reviews: #{games.size} games to scrap!"
    puts '============================================'

    scrapper.scrap do |game, page|
      puts "#{game.name} / Page #{page}"
    end
  end

  def save
    Game.all.each do |game|  
      game.save!
    end
    Game.save_to_file
  end
end 