require 'json'
require 'nokogirl'
require 'yell'
require 'mail'

require_relative 'lib/array'
require_relative 'lib/object'
require_relative 'lib/scrapper'
require_relative 'lib/games_scrapper'
require_relative 'lib/reviews_scrapper'
require_relative 'lib/scrapping_overlord'
require_relative 'lib/games_collection'
require_relative 'models/game'

Log = Yell.new STDOUT

NOTIFICATIONS_EMAIL_TO = 'zequez@gmail.com'

Mail.defaults do
	delivery_method :smtp, enable_starttls_auto: false
end