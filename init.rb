require 'json'
require 'nokogiri'
require 'yell'
require 'mail'
require 'active_record'

require_relative 'lib/array'
require_relative 'lib/scrapper'
require_relative 'lib/games_list_scrapper'
require_relative 'lib/reviews_scrapper'
require_relative 'lib/game_scrapper'
require_relative 'lib/scrapping_overlord'
require_relative 'models/game_ar'
require_relative 'models/price'

ENV['APP_ENV'] ||= 'development'
env = ENV['APP_ENV']

Log = Yell.new do |l|
  l.adapter :datefile, "log/#{env}.log", 
            level: [:debug, :info, :warn, :error, :fatal], 
            keep: 5,
            date_pattern: '%Y-%m'

  if ENV['APP_ENV'] == 'development'
    l.adapter STDOUT, format: '[%5L] %m'
  end
end

NOTIFICATIONS_EMAIL_TO = 'zequez@gmail.com'

MAX_REVIEWS = 1000

Mail.defaults do
	delivery_method :smtp, enable_starttls_auto: false
end

I18n.enforce_available_locales = false

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: "db/#{env}.sqlite3", timeout: 30000, pool: 15)