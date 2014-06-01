module PtbScrapper
  module Logger
    def logger
      Logger.logger
    end

    def self.logger
      @logger ||= set_default_logger
    end

    def self.logger=(logger)
      @logger = logger
    end

    private

    def self.set_default_logger
      @logger = begin
        log_file = File.join PtbScrapper.config.log_directory, "#{APP_ENV}.log"
        FileUtils.mkpath PtbScrapper.config.log_directory

        Yell.new do |l|
          l.adapter :datefile,
                    log_file,
                    keep: 5,
                    date_pattern: '%Y-%m',
                    symlink: false # Cause I'm running in a VM shared folder

          if APP_ENV == 'development'
            l.adapter STDOUT, format: '[%5L] %m'
          end
        end
      end
    end
  end
end