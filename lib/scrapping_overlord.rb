require 'fileutils'

class ScrappingOverlord
  NOTIFICATIONS_EMAIL_FROM = 'PlaytimeForTheBuck ScrapperBot <scrapper@playtimeforthebuck.com>'

  def initialize(files_path = 'db')
    @file_name = Time.now.strftime '%Y-%m-%d.%H-%M-%S'
    file_extension = 'json'
    file_path = "#{files_path}/#{@file_name}.#{file_extension}"

    FileUtils.mkdir files_path if not File.directory? files_path

    last_file = Dir.glob("#{files_path}/*").last
    if last_file
      FileUtils.cp last_file, file_path
    else
      FileUtils.touch file_path
    end

    file = File.open file_path, 'a+'
    Game.set_file file
  end

  def scrap_games
    games = Game.all
    scrapper = GamesScrapper.new games

    Log.info "Scrapping games: #{games.size} are the current games!"
    Log.info '============================================'

    begin
      scrapper.scrap do |page_games|
        Log.info "#{page_games.size} games in this page #{scrapper.last_page_url}"
      end
    rescue Scrapper::InvalidHTML => e
      Log.error "ERROR: Invalid HTML!"
      send_error_email e, scrapper.last_page, scrapper.last_page_url
    end
  end

  def scrap_reviews
    games = Game.get_for_reviews_updating
    scrapper = ReviewsScrapper.new games

    Log.info "Scrapping reviews: #{games.size} games to scrap!"
    Log.info '============================================'

    begin
      scrapper.scrap do |game, page|
        Log.info "#{game.name} / Page #{page}"
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
  end

  private

  def send_error_email(exception, faulty_page, faulty_page_url)
    time = Time.now.strftime '%Y-%m-%d.%H-%M-%S'
    page_attachment_name = faulty_page_url.gsub(/[^\w\.]/, '_')
    page_attachment_path = "tmp/#{time}-#{page_attachment_name}.html"
    
    FileUtils.mkdir 'tmp' if not File.directory? 'tmp'
    File.open page_attachment_path, 'w+' do |f|
      f.write faulty_page
    end

    Mail.deliver do
      from NOTIFICATIONS_EMAIL_FROM
      to NOTIFICATIONS_EMAIL_TO
      subject 'There was an HTML error on the PlaytimeForTheBuck scrapper!'
      body %Q{
        Here is the scrapped page attached, and the traceback, 
        fix it ASAP! Thanks, me!

        The page that generated te error was

        #{faulty_page_url}

        #{$!.backtrace}
      }

      add_file page_attachment_path
    end
  end
end 