require 'fileutils'

module PtbScrapper
  class ScrappingOverlord
    include Logger

    def initialize(relative_file_name = 'db/games.json', games_class = Models::GameAr)
      @games_class = games_class
      @file_name = relative_file_name#File.expand_path relative_file_name, __FILE__
    end

    def scrap_games_list(autosave = true)
      games = @games_class.all
      scrapper = Scrappers::GamesListScrapper.new games, @games_class

      logger.info "Scrapping games: #{games.size} are the current games!"
      logger.info '============================================'
      begin
        begin
          scrapper.scrap(autosave) do |new_games, old_games, page|
            logger.info "#{new_games.size} new games, #{old_games.size} old games in page #{page}"
          end
        rescue Scrappers::InvalidHTML => e
          logger.error "ERROR: Invalid HTML!", scrapper.last_page_url
          send_error_email e, scrapper.last_page, scrapper.last_page_url
        end
      rescue Scrappers::NoServerConnection => e
        logger.error 'ERROR: No server connection on page next to the previous page'
      end

      scrapper.subjects
    end

    def scrap_reviews(autosave = true)
      games = @games_class.get_for_reviews_updating
      scrapper = Scrappers::ReviewsScrapper.new games, @games_class

      logger.info "Scrapping reviews: #{games.size} games to scrap!"
      logger.info '============================================'

      begin
        counter = 0
        times = []
        previous_time = Time.now.to_i
        scrapper.scrap(autosave) do |game, reviews, finished_game|
          game_name = game.name[0...30].ljust(30)

          reviews_count = reviews ? reviews[:positive].size + reviews[:negative].size : '???'
          finished = ''
          if finished_game
            counter += 1
            

            current_time = Time.now.to_i
            times.unshift current_time - previous_time
            times = times[0...25]
            average_time = (times.reduce(:+) / Float(times.size))
            previous_time = current_time
            time_left_minutes = (average_time*(games.size-counter) / 60).round(2)

            finished = "FINISHED! #{counter}/#{games.size} - #{time_left_minutes} minutes left"
          end

          logger.info "#{game_name} - Reviews: #{reviews_count} #{finished}"
        end
      rescue Scrappers::InvalidHTML => e
        logger.error "ERROR: Invalid HTML!", scrapper.last_page_url
        send_error_email e, scrapper.last_page, scrapper.last_page_url
      end

      scrapper.subjects
    end

    def scrap_games(autosave = true)
      games = @games_class.get_for_games_updating
      scrapper = Scrappers::GameScrapper.new games, @games_class

      logger.info "Scrapping categories: #{games.size} games to scrap!"
      logger.info '============================================'
      begin
        counter = 0
        scrapper.scrap(autosave) do |game|
          current_game = games.index(game) + 1
          pagination = "#{current_game}/#{games.size}".ljust(10)
          game_name = game.name[0...30].ljust(30)
          counter += 1
          categories = game.categories.size

          logger.info "#{game_name} - #{pagination} - Categories: #{categories} - #{counter}/#{games.size}"
        end
      rescue Scrappers::InvalidHTML => e
        logger.error "ERROR: Invalid HTML! #{e.message} #{e.url}"
        send_error_email e, e.html, e.url
      end

      scrapper.subjects
    end

    def create_summary
      games = @games_class.get_for_summary
      os_flags = @games_class::OS_FLAGS
      features_flags = @games_class::FEATURES_FLAGS
      tags = {}

      data = {
        games: games.map(&:summary_attrs),
        osFlags: camelize_hash(os_flags),
        featuresFlags: camelize_hash(features_flags),
        tags: tags
      }

      data[:games].each{ |g| camelize_hash! g }

      file_path = File.dirname(@file_name)
      FileUtils.mkpath file_path if not File.directory? file_path

      @file = File.open @file_name, 'w'
      @file.truncate 0
      @file.rewind
      @file.write data.to_json
      @file.close

      logger.info "Generated summary file!"
    end

    private

    def camelize_hash(hash)
      camelize_hash! hash.dup
    end

    # TODO: Move this to a separate class
    def camelize_hash!(hash)
      hash.keys.each do |k|
        new_key = camelize_key(k.to_s)
        new_key = new_key.to_sym if k.is_a? Symbol
        hash[new_key] = hash.delete(k)
      end
      hash
    end

    def camelize_key(str)
      str = str.split('_').map {|w| w.capitalize}.join
      str[0, 1].downcase + str[1..-1]
    end

    def send_error_email(exception, faulty_page, faulty_page_url)
      time = Time.now.strftime '%Y-%m-%d.%H-%M-%S'
      page_attachment_name = faulty_page_url.gsub(/[^\w\.]/, '_')[0, 100]
      page_attachment_path = "tmp/#{time}-#{page_attachment_name}.html"
      
      FileUtils.mkdir 'tmp' if not File.directory? 'tmp'
      File.open page_attachment_path, 'w+' do |f|
        f.write faulty_page
      end

      backtrace = $!.backtrace.join("\n");

      from_email = PtbScrapper.config.notifications_email_from
      from_name = PtbScrapper.config.notifications_email_from_name

      Mail.deliver do
        from "#{from_name} <#{from_email}>"
        to PtbScrapper.config.notifications_email_to
        subject 'There was an HTML error on the PlaytimeForTheBuck scrapper!'
        body %Q{
          Here is the scrapped page attached, and the traceback, 
          fix it ASAP! Thanks, me!

          The page that generated te error was

          #{faulty_page_url}

          #{backtrace}
        }

        add_file page_attachment_path
      end
    end
  end
end