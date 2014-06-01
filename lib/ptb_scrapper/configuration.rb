module PtbScrapper
  class Configuration
    attr_accessor :game_class, :log_directory, 
                  :max_reviews, :db_config_path, 
                  :notifications_email_to, :notifications_email_from,
                  :notifications_email_from_name

    def initialize
      @game_class = PtbScrapper::Models::GameAr
      @log_directory = 'log/'
      @max_reviews = 1000
      @db_config_path = './db/config.yml'
      @notifications_email_to = 'zequez@gmail.com'
      @notifications_email_from = 'scrapper@playtimeforthebuck.com'
      @notifications_email_from_name = 'PlaytimeForTheBuck ScrapperBot@playtimeforthebuck.com'
    end

    def logger=(logger)
      Logger.logger = logger
    end

    def logger
      Logger.logger
    end
  end
end