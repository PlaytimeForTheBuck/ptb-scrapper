require 'net/http'
require 'nokogirl'

class ReviewsScrapper < Scrapper
  attr_reader :last_page, :last_page_url

  def self.url(app_id, page = 1)
    offset = (page-1)*10
    "http://steamcommunity.com/app/#{app_id}/homecontent/?l=english&userreviewsoffset=#{offset}&p=#{page}&itemspage=2&screenshotspage=2&videospage=2&artpage=2&allguidepage=2&webguidepage=2&integratedguidepage=2&discussionspage=2&appHubSubSection=10&browsefilter=toprated&filterLanguage=default&searchText="
  end

  def initialize(games)
    @games = games
  end

  def scrap
    games.each do |game|

      array_positive_reviews = []
      array_negative_reviews = []
      page = 1

      begin
        page_url = @last_page_url = ReviewsScrapper.url(game.steam_app_id, page)
        raw_page = @last_page = Net::HTTP.get URI page_url

        doc = Nokogiri::HTML raw_page

        if not raw_page.blank?
          doc.search('.apphub_Card').each do |e_review|
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
            raise InvalidHTML if e_hours.nil?
            hours = e_hours.content.match(/^[0-9]+\.?[0-9]*/)
            raise InvalidHTML if hours.nil?
            hours = Float(hours[0])

            if positivity
              array_positive_reviews.push hours
            else
              array_negative_reviews.push hours 
            end
          end

          yield game, page if block_given?

          page += 1
        end
      end while not raw_page.blank?

      game.array_positive_reviews = array_positive_reviews
      game.array_negative_reviews = array_negative_reviews

      game.update_reviews!
    end
  end
end