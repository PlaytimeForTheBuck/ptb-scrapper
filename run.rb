require './init'

SCRAP_GAMES = ! ARGV.include?('--no-games')
SCRAP_REVIEWS = ! ARGV.include?('--no-reviews')
SAVE_GAMES = ! ARGV.include?('--no-save')

scrapper = ScrappingOverlord.new

if SCRAP_GAMES
	scrapper.scrap_games

	if SAVE_GAMES
		scrapper.save
	end
end

if SCRAP_REVIEWS
	scrapper.scrap_reviews(save_after_each_game: SAVE_GAMES)

	if SAVE_GAMES
		scrapper.save
	end
end