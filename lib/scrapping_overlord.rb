require 'fileutils'

class ScrappingOverlord
  NOTIFICATIONS_EMAIL_FROM = 'PlaytimeForTheBuck ScrapperBot <scrapper@playtimeforthebuck.com>'

  def initialize(files_path = 'db', summary_files_path = 'summary_db')
    @file_name = Time.now.strftime '%Y-%m-%d.%H-%M-%S'
    file_extension = 'json'
    file_path = "#{files_path}/#{@file_name}.#{file_extension}"
    summary_file_path = "#{summary_files_path}/#{@file_name}.#{file_extension}"

    FileUtils.mkdir files_path if not File.directory? files_path
    FileUtils.mkdir summary_files_path if not File.directory? summary_files_path

    last_file = Dir.glob("#{files_path}/*").last
    if last_file
      FileUtils.cp last_file, file_path
    else
      FileUtils.touch file_path
    end

    @file = File.open file_path, 'a+'
    @summary_file = File.open summary_file_path, 'w'
    Game.set_file @file
  end

  def scrap_games
    games = Game.all
    scrapper = GamesScrapper.new games

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
  end

  def scrap_reviews(options = {}) # And categories
    options = {save_after_each_game: false}.merge(options)

    games = Game.get_for_reviews_updating
    scrapper = ReviewsScrapper.new games
    categories_scrapper = CategoriesScrapper.new games

    Log.info "Scrapping reviews and categories: #{games.size} games to scrap!"
    Log.info '============================================'

    begin
      previous_game = nil
      categories_scrapper.scrap do |game, data, page|
        Log.info "#{game.name} / Categories: #{data.join(',')}"
      end

      scrapper.scrap do |game, data, page|
        Log.info "#{game.name} / Page #{page}"
        if game != previous_game
          if previous_game and options[:save_after_each_game]
            previous_game.save
            Game.save_to_file
            Game.save_summary_to_file(@summary_file)
          end
          previous_game = game
        end
      end
    rescue Scrapper::InvalidHTML => e
      Log.error "ERROR: Invalid HTML!"
      send_error_email e, scrapper.last_page, scrapper.last_page_url
    end
  end

  def save
    Game.all.each do |game|  
      game.save!
    end
    Game.save_to_file
    Game.save_summary_to_file(@summary_file)
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