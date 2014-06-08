require 'json'
require 'nokogiri'
require 'yell'
require 'mail'
require 'active_record'
require 'yaml'

require 'ptb_scrapper/configuration'
require 'ptb_scrapper/logger'
require 'ptb_scrapper/ex_array'
require 'ptb_scrapper/scrappers'
require 'ptb_scrapper/scrappers/scrapper'
require 'ptb_scrapper/scrappers/game_scrapper'
require 'ptb_scrapper/scrappers/games_list_scrapper'
require 'ptb_scrapper/scrappers/reviews_scrapper'
require 'ptb_scrapper/models'
require 'ptb_scrapper/models/flags_attributes'
require 'ptb_scrapper/models/game_ar'
require 'ptb_scrapper/models/price'
require 'ptb_scrapper/scrapping_overlord'

module PtbScrapper  
  class << self
    attr_accessor :config

    Mail.defaults do
      delivery_method :smtp, enable_starttls_auto: false
    end

    def init
      self.config ||= Configuration.new

      I18n.enforce_available_locales = false 
      
      if not ActiveRecord::Base.connected?
        db_config = YAML.load_file('./db/config.yml')
        ActiveRecord::Base.establish_connection db_config[PtbScrapper.env]
      end
    end

    def reset
      self.config = Configuration.new
      Logger.set_default_logger
    end

    def setup
      init
      self.config = Configuration.new
      yield config
    end

    def load_rake_tasks
      load 'ptb_scrapper/tasks.rake'
    end

    def env
      ENV['APP_ENV'] || ENV['RAILS_ENV'] || 'development'
    end

    def root
      File.expand_path('../..', __FILE__)
    end
  end
end