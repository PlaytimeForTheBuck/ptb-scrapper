class GamesListScrapper < Scrapper
  attr_reader :last_page, :last_page_url

  # TODO: We shouldn't nee this for testing
  # It's the remain of the previous implementation
  def self.url(page = 1, country = 'us')
    GamesListScrapper.new([]).get_url(nil, page-1, 0)
  end

  def get_url(doc, index, _)
    page = index + 1
    country = 'us'
    "http://store.steampowered.com/search/results?category1=998&sort_by=Name&sort_order=ASC&category1=998&cc=us&v5=1&page=#{page}"
  end

  private

  def parse_page(doc, group, group_data)
    data = []
    doc.search('.search_result_row').each do |a|
      begin
        attrs = {}

        # Get the name
        attrs[:name] = read_name(a)

        # Get Steam App ID
        attrs[:steam_app_id] = read_steam_app_id(a)

        # Get the release date
        attrs[:launch_date] = read_release_date(a)

        # Get the meta score
        attrs[:meta_score] = read_meta_score(a)

        # Get the prices
        attrs[:price], attrs[:sale_price] = read_prices(a)

        data.push attrs
      rescue InvalidGame => e
        # We just ignore the game.
      end
    end
    data
  end

  def save_data(games_attrs, group)
    new_games = []
    old_games = []

    games_attrs.each do |attrs|
      game = get_by_id attrs[:steam_app_id]
      new_game = !game 
      if new_game
        game = GameAr.new(attrs)
        new_games.push game
        add_subject game
      else
        game.assign_attributes attrs
        old_games.push game
      end
      game.update_game_list!
      queue_save game
    end

    yield(new_games, old_games, last_page) if block_given?
  end

  def keep_scrapping_after?(doc, group_data)
    e_next_page = doc.search('.search_pagination_right a').last
    raise InvalidHTML if e_next_page.nil?
    e_next_page.content == '>>'
  end

  def read_name(a)
    e_name = a.search('.search_name h4').first
    raise InvalidHTML if e_name.nil?
    e_name.content.strip
  end

  def read_steam_app_id(a)
    steam_app_id = a['href']
    raise InvalidHTML if steam_app_id.blank? 
    steam_app_id = steam_app_id.match(/app\/([0-9]+)/)
    raise InvalidHTML if steam_app_id.blank?
    steam_app_id[1].to_i
  end

  def read_release_date(a)
    e_release_date = a.search('.search_released').first
    raise InvalidHTML if e_release_date.nil?
    release_date = e_release_date.content
    if release_date.blank?
      release_date = nil
    else
      begin
        release_date = Time.parse release_date
      rescue
        raise InvalidGame, "Invalid release date #{release_date}"
      end
      raise InvalidGame if release_date > Time.now
    end
    release_date
  end

  def read_meta_score(a)
    e_meta_score   = a.search('.search_metascore').first
    raise InvalidHTML if e_meta_score.nil?
    meta_score = e_meta_score.content
    if meta_score.blank?
      meta_score = nil
    else
      meta_score = meta_score.match(/[0-9]+/)
      raise InvalidHTML if meta_score.nil?
      meta_score = Integer meta_score[0]
    end
    meta_score
  end

  def read_prices(a)
    e_price_container = a.search('.search_price')
    raise InvalidHTML if e_price_container.size != 1
    e_previous_price = e_price_container.search('strike')
    in_sale = (e_previous_price.size == 1)
    # In sale format
    if in_sale
      price = e_previous_price.first.content.sub('$', '')
      sale_price = e_price_container.first.content.match(/[0-9.]+$/)
      raise InvalidHTML if sale_price == nil
      sale_price = sale_price[0]
    # In regular format
    else
      old_price = e_price_container.first.content
      price = e_price_container.first.content.sub('$', '')
      sale_price = nil
    end

    raise InvalidGame if price.nil?
    price = price.downcase.gsub(/[^a-z0-9. ]/, ' ').gsub(/\s+/, ' ').strip
    raise InvalidGame if price =~ /demo/i

    means_its_free = ['free to play', 'play for free', 'free', 'third party']
    price = 0 if price =~ /free/i or means_its_free.include? price
    sale_price = nil if sale_price =~ /free/i or means_its_free.include? sale_price

    begin
      price = price.blank? ? nil : Float(price)
      sale_price = sale_price.blank? ? nil : Float(sale_price)
    rescue => e
      raise InvalidHTML, "Invalid price #{price}, #{sale_price}"
    end

    return price, sale_price
  end
end