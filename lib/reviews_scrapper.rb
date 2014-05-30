class ReviewsScrapper < Scrapper
  attr_reader :last_page, :last_page_url

  def self.url(app_id, page = 1)
    offset = (page-1)*10
    "http://steamcommunity.com/app/#{app_id}/homecontent/?l=english&userreviewsoffset=#{offset}&p=#{page}&itemspage=2&screenshotspage=2&videospage=2&artpage=2&allguidepage=2&webguidepage=2&integratedguidepage=2&discussionspage=2&appHubSubSection=10&browsefilter=toprated&filterLanguage=default&searchText="
  end

  def get_url(doc, index, game)
    app_id = game.steam_app_id
    offset = index * 10
    page = index + 1
    "http://steamcommunity.com/app/#{app_id}/homecontent/?l=english&userreviewsoffset=#{offset}&p=#{page}&itemspage=2&screenshotspage=2&videospage=2&artpage=2&allguidepage=2&webguidepage=2&integratedguidepage=2&discussionspage=2&appHubSubSection=10&browsefilter=toprated&filterLanguage=default&searchText="
  end

  def parse_page(doc, game, reviews)
    reviews = reviews || { positive: [], negative: [] }

    doc.search('.apphub_Card').each do |e_review|
      begin
        e_abusive = e_review.search('.UserReviewCardContent_FlaggedByDeveloper').first
        raise InvalidReview if not e_abusive.nil?

        e_thumb = e_review.search('.thumb img').first
        raise InvalidHTML if e_thumb.nil?
        src = e_thumb['src']
        raise InvalidHTML if src.nil?
        if src.match('icon_thumbsUp')
          positivity = true
        elsif src.match('icon_thumbsDown')
          positivity = false
        else
          raise InvalidHTML
        end

        e_hours = e_review.search('.hours').first
        raise InvalidReview if e_hours.nil?
        hours = e_hours.content.match(/^[0-9]+\.?[0-9]*/)
        raise InvalidHTML if hours.nil?
        hours = Float(hours[0])

        if positivity
          reviews[:positive].push hours
        else
          reviews[:negative].push hours
        end
      rescue InvalidReview => e
        # We just ignore it
      end
    end

    yield game, reviews, false if block_given?

    reviews
  end

  def save_group_data(reviews, game)
    if not reviews.nil?
      game.positive_reviews = reviews[:positive]
      game.negative_reviews = reviews[:negative]
    end
    game.update_reviews!
    queue_save game
    yield game, reviews, true if block_given?
  end

  def scrapping_groups
    subjects
  end

  def keep_scrapping_after?(doc, group_data)
    return true if group_data.nil?
    group_data[:positive].size + group_data[:negative].size < MAX_REVIEWS
  end
end