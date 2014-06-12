require 'net/http'
require 'nokogiri'

module PtbScrapper
  module Scrappers
    class GameScrapper < Scrapper
      # This is to simplify testing, to mock the URL
      def self.url(app_id)
        "http://store.steampowered.com/app/#{app_id}"
      end

      def get_url(doc, index, game)
        game.steam_app_id
        self.class.url(game.steam_app_id)
      end

      def parse_page(_, params)
        doc = params[:doc]

        e_error = doc.search('.error').first
        if not e_error.nil? and e_error.text == 'This item is currently unavailable in your region'
          return nil
        end

        data = {
          tags: nil,
          os: [],
          features: []
        }

        # Tags
        script_tags = doc.search('script')

        script_tags.each do |script_tag|
          if script_tag.text =~ /InitAppTagModal/
            tags_array = script_tag.text.scan(/"tagid":[0-9]+,"name":"([^"]+)"/).flatten
            data[:tags] = tags_array
          end
        end

        if data[:tags].nil?
          invalid_html! params, "Couldn't find any tag"
        end

        # Operative Systems

        data[:os].push :win if doc.search('.platform_img.win').first != nil
        data[:os].push :mac if doc.search('.platform_img.mac').first != nil
        data[:os].push :linux if doc.search('.platform_img.linux').first != nil

        # Features

        features_tags = doc.search('.game_area_details_specs .name a')
        data[:features].push :multi_player       unless features_tags.filter('[href$="1"]').empty?
        data[:features].push :achievements       unless features_tags.filter('[href$="22"]').empty?
        data[:features].push :stats              unless features_tags.filter('[href$="15"]').empty?
        data[:features].push :vac                unless features_tags.filter('[href$="8"]').empty?
        data[:features].push :partial_controller unless features_tags.filter('[href$="18"]').empty?
        data[:features].push :cards              unless features_tags.filter('[href$="29"]').empty?
        data[:features].push :workshop           unless features_tags.filter('[href$="30"]').empty?
        data[:features].push :captions           unless features_tags.filter('[href$="13"]').empty?
        data[:features].push :commentary         unless features_tags.filter('[href$="14"]').empty?
        data[:features].push :vr                 unless features_tags.filter('[href$="31"]').empty?
        data[:features].push :level_editor       unless features_tags.filter('[href$="17"]').empty?
        data[:features].push :leaderboards       unless features_tags.filter('[href$="25"]').empty?
        data[:features].push :controller         unless features_tags.filter('[href$="28"]').empty?
        data[:features].push :co_op              unless features_tags.filter('[href$="9"]').empty?
        data[:features].push :cloud              unless features_tags.filter('[href$="23"]').empty?
        data[:features].push :single_player      unless features_tags.filter('[href$="2"]').empty?

        data[:features].push(:partial_controller) if data[:features].include? :controller

        data
      end

      def save_data(data, game)
        if data
          game.categories = data[:tags]
          game.os = data[:os]
          game.features = data[:features]
          game.update_game!
          queue_save game
        end
        yield(game) if block_given?
      end

      # This way we only scrap once per group
      def keep_scrapping_after?(doc, group_data)
        false
      end

      def scrapping_groups
        subjects
      end
    end
  end
end