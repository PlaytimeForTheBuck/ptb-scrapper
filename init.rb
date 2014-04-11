require 'json'
require 'nokogirl'
require 'yell'

require_relative 'lib/array' 
require_relative 'lib/object' 
require_relative 'lib/scrapper'
require_relative 'lib/games_scrapper'
require_relative 'lib/reviews_scrapper'
require_relative 'lib/scrapping_overlord'
require_relative 'lib/games_collection'
require_relative 'models/game'

Log = Yell.new STDOUT