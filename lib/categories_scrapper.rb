require 'net/http'
require 'nokogiri'

class CategoriesScrapper < Scrapper
  # This is to simplify testing, to mock the URL
  def self.url(app_id)
    "http://store.steampowered.com/app/#{app_id}"
  end

  def get_url(doc, index, group_index)
    game = subjects[group_index]
    game.steam_app_id
    self.class.url(game.steam_app_id)
  end

  def parse_page(doc, game, reviews)
    script_tags = doc.search('script')

    data = nil

    script_tags.each do |script_tag|
      if script_tag.text =~ /InitAppTagModal/
        tags_array = script_tag.text.scan(/"tagid":[0-9]+,"name":"([^"]+)"/).flatten
        data = tags_array
      end
    end

    Log.debug data

    if data.nil?
      raise InvalidHTML
    end

    data
  end

  def save_data(tags_array, game)
    game.categories = tags_array
  end

  # This way we only scrap once per group
  def keep_scrapping_after?(doc)
    false
  end

  def scrapping_groups
    subjects
  end
end