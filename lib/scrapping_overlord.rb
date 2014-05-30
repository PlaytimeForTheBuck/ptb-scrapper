require 'fileutils'

class ScrappingOverlord
  NOTIFICATIONS_EMAIL_FROM = 'PlaytimeForTheBuck ScrapperBot <scrapper@playtimeforthebuck.com>'

  def initialize(relative_file_name = 'db/games.json')
    file_name = relative_file_name#File.expand_path relative_file_name, __FILE__
    file_path = File.dirname(file_name)

    FileUtils.mkpath file_path if not File.directory? file_path

    @file = File.open file_name, 'w'
  end

  def scrap_games_list(autosave = true)
    games = GameAr.all
    scrapper = GamesListScrapper.new games

    Log.info "Scrapping games: #{games.size} are the current games!"
    Log.info '============================================'
    begin
      begin
        scrapper.scrap(autosave) do |new_games, old_games, page|
          # new_games.first.save! if autosave
          # new_games.each(&:save!) if autosave
          # old_games.each(&:save!) if autosave
          Log.info "#{new_games.size} new games, #{old_games.size} old games in page #{page}"
        end
      rescue Scrapper::InvalidHTML => e
        Log.error "ERROR: Invalid HTML!", scrapper.last_page_url
        send_error_email e, scrapper.last_page, scrapper.last_page_url
      end
    rescue Scrapper::NoServerConnection => e
      Log.error 'ERROR: No server connection on page next to the previous page'
    end

    create_summary scrapper.subjects if autosave
    scrapper.subjects
  end

  def scrap_reviews(autosave = true)
    games = GameAr.get_for_reviews_updating
    scrapper = ReviewsScrapper.new games

    Log.info "Scrapping reviews: #{games.size} games to scrap!"
    Log.info '============================================'

    begin
      counter = 0
      scrapper.scrap(autosave) do |game, reviews, finished_game|
        reviews_count = reviews ? reviews[:positive].size + reviews[:negative].size : '???'
        finished = finished_game ? 'FINISHED! ' : ''
        current_game = games.index(game) + 1
        pagination = "#{current_game}/#{games.size}".ljust(10)
        game_name = game.name[0...30].ljust(30)
        if finished_game
          counter += 1
          finished += "#{counter}/#{games.size}"
        end

        Log.info "#{game_name} - #{pagination} - Reviews: #{reviews_count} #{finished}"

        # game.save! if autosave and finished_game
      end
    rescue Scrapper::InvalidHTML => e
      Log.error "ERROR: Invalid HTML!", scrapper.last_page_url
      send_error_email e, scrapper.last_page, scrapper.last_page_url
    end

    create_summary scrapper.subjects if autosave
    scrapper.subjects
  end

  def scrap_games(autosave = true)
    games = GameAr.get_for_games_updating
    scrapper = GameScrapper.new games

    Log.info "Scrapping categories: #{games.size} games to scrap!"
    Log.info '============================================'
    begin
      scrapper.scrap(autosave) do |game|
        # game.save! if autosave

        categories = game.categories.join(', ')
        current_page = games.index(game) + 1
        Log.info "#{current_page}/#{games.size} - #{game.name} - Categories: #{categories}"
      end
    rescue Scrapper::InvalidHTML => e
      Log.error 'ERROR: Invalid HTML!', scrapper.last_page_url
      send_error_email e, scrapper.last_page, scrapper.last_page_url
    end

    create_summary scrapper.subjects if autosave
    scrapper.subjects
  end

  def close
    @file.close
  end

  def create_summary(games)
    @file.truncate 0
    @file.rewind
    @file.write games.to_json
  end

  private

  def send_error_email(exception, faulty_page, faulty_page_url)
    time = Time.now.strftime '%Y-%m-%d.%H-%M-%S'
    page_attachment_name = faulty_page_url.gsub(/[^\w\.]/, '_')[0, 100]
    page_attachment_path = "tmp/#{time}-#{page_attachment_name}.html"
    
    FileUtils.mkdir 'tmp' if not File.directory? 'tmp'
    File.open page_attachment_path, 'w+' do |f|
      f.write faulty_page
    end

    backtrace = $!.backtrace.join("\n");

    Mail.deliver do
      from NOTIFICATIONS_EMAIL_FROM
      to NOTIFICATIONS_EMAIL_TO
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