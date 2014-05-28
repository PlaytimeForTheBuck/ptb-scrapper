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
        scrapper.scrap do |_, page_games_data, _|
          Log.info "#{page_games_data.size} games in this page #{scrapper.last_page_url}"
        end
      rescue Scrapper::InvalidHTML => e
        Log.error "ERROR: Invalid HTML!"
        send_error_email e, scrapper.last_page, scrapper.last_page_url
      end
    rescue Scrapper::NoServerConnection => e
      Log.error 'ERROR: No server connection on page next to the previous page'
    end

    save(games) if autosave
    games
  end

  def scrap_reviews(autosave = true)
    games = GameAr.get_for_reviews_updating
    scrapper = ReviewsScrapper.new games

    Log.info "Scrapping reviews: #{games.size} games to scrap!"
    Log.info '============================================'

    begin
      previous_game = nil

      scrapper.scrap do |game, data, page|
        Log.info "#{game.name} / Page #{page}"
        if autosave and game != previous_game
          previous_game.save! if not previous_game.nil?
          previous_game = game
        end
      end
    rescue Scrapper::InvalidHTML => e
      Log.error "ERROR: Invalid HTML!"
      send_error_email e, scrapper.last_page, scrapper.last_page_url
    end

    save(games) if autosave

    games
  end

  def scrap_categories(autosave = true)
    games = GameAr.get_for_games_updating
    scrapper = GameScrapper.new games

    Log.info "Scrapping categories: #{games.size} games to scrap!"
    Log.info '============================================'
    begin
      scrapper.scrap do |game, data, page|
        game.save! if autosave

        categories = data.nil? ? '???' : data.join(',')
        Log.info "#{game.name} / Categories: #{categories}"
      end
    rescue Scrapper::InvalidHTML => e
      Log.error 'ERROR: Invalid HTML!'
      send_error_email e, scrapper.last_page, scrapper.last_page_url
    end

    save(games) if autosave

    games
  end

  def close
    @file.close
  end

  def save(games)
    games.each do |game|  
      game.save!
    end

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