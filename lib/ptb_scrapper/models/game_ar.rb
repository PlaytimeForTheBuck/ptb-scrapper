require 'json'
require 'time'

module PtbScrapper
  module Models
    class GameAr < ActiveRecord::Base
      extend FlagsAttributes

      PLAYTIME_DEVIATION_PERCENTAGE = 0.25

      self.table_name = 'games'

      alias_attribute :steam_app_id, :id

      has_many :price_history, class_name: 'Price', foreign_key: 'game_id'

      serialize :categories, JSON
      serialize :positive_reviews, JSON
      serialize :negative_reviews, JSON

      after_initialize :init_defaults

      def init_defaults
        self.categories ||= []
        self.positive_reviews ||= []
        self.negative_reviews ||= []
      end

      ########## Finders ##########
      #############################

      def self.get_for_reviews_updating
        get_for_x_updating(:reviews_updated_at)
      end

      def self.get_for_games_updating
        get_for_x_updating(:game_updated_at)
      end

      def self.get_for_summary
        order(:name)
      end

      # Gets the games that need an update based on a last updated_at attribute
      # By the age of the game
      # the time for updating is:
      #   1 week game: 1 day
      #   1 month game: 7 days
      #   1 year game: 1 month
      #   3 years game: 3 months
      #   3+ years game: 1 year
      def self.get_for_x_updating(updated_at_attribute)
        day_ago    = Time.now - 3600*24           # 1 day ago
        week_ago   = Time.now - 3600*24*7         # 1 week ago
        month_ago  = Time.now - 3600*24*30        # 1 month ago
        months_ago = Time.now - 3600*24*30*3      # 3 months ago
        year_ago   = Time.now - 3600*24*365       # 1 year ago
        years_ago  = Time.now - 3600*24*365*3     # 3 years ago

        a = updated_at_attribute
        query = order(:name).where("#{a} IS NULL
        OR ( launch_date IS NULL AND #{a} < ? )
        OR ( launch_date > ? AND #{a} < ? )
        OR ( launch_date > ? AND #{a} < ? )
        OR ( launch_date > ? AND #{a} < ? )
        OR ( launch_date > ? AND #{a} < ? )
        OR (#{a} < ?)",
        months_ago,
        week_ago, day_ago,
        month_ago, week_ago,
        year_ago, month_ago,
        years_ago, months_ago,
        year_ago)

        # Log.debug query.to_sql

        return query

        # I'm gonna leave this just in case

        # order(:name).all.select do |game|
        #   date     = game.read_attribute updated_at_attribute
        #   # If no launch date we treat it like a year ago
        #   launched = game.launch_date ? game.launch_date : year_ago
          
        #   # The game was never updated?
        #   if date == nil
        #     true
        #   # Launch date unknown
        #   elsif launched == nil
        #     date < months_ago
        #   # Launched less than a week ago?
        #   elsif launched > week_ago
        #     # Updated more than a day ago?
        #     date < day_ago
        #   # Launched less than a month ago?
        #   elsif launched > month_ago
        #     # Updated more than a week ago?
        #     date < week_ago
        #   # Launched less than a year ago?
        #   elsif launched > year_ago 
        #     # Updated more than a month ago?
        #     date < month_ago
        #   # Launched less than 3 years ago?
        #   elsif launched > years_ago
        #     # Updated more than 3 months ago
        #     date < months_ago
        #   else # Launched more than 3 years ago?
        #     # Updated more than a year ago
        #     date < year_ago
        #   end
        # end
      end

      def self.expire_games
        update_all(game_updated_at: nil)
      end
     
      ########## Validations ##########
      #################################

      validates :name, presence: true
      validates :steam_app_id, presence: true
      # validates :price, presence: true

      validate :are_positive_reviews_numeric?
      validate :are_negative_reviews_numeric?

      def are_positive_reviews_numeric?
        if not PtbScrapper::ExArray.new(positive_reviews).all_numeric?
          errors.add :positive_reviews, "Positive reviews aren't numeric"
        end
      end

      def are_negative_reviews_numeric?
        if not PtbScrapper::ExArray.new(negative_reviews).all_numeric?
          errors.add :negative_reviews, "Negative reviews aren't numeric"
        end
      end

      ########## Save callbacks ##########
      ####################################

      before_save :save_to_price_history

      def save_to_price_history
        if not new_record? and (price_changed? or sale_price_changed?)
          self.price_history.create price: price_was,
                                    sale_price: sale_price_was,
                                    date: game_list_updated_at_was
        end
      end  

      ########## Methods ##########
      #############################

      def reviews
        positive_reviews.dup.concat negative_reviews
      end

      def on_sale?
        not sale_price.nil?
      end

      def sale_discount
        if on_sale?
          (price - sale_price) / price.to_f * 100.0
        else
          0
        end
      end

      def categories=(categories_array)
        unless categories_array.nil?
          write_attribute(:categories, categories_array[0...10])
        end
      end

      def positive_reviews=(reviews_array)
        reviews_array = reviews_array.kind_of?(Array) ? reviews_array : []
        write_attribute(:positive_reviews, reviews_array)
      end

      def negative_reviews=(reviews_array)
        reviews_array = reviews_array.kind_of?(Array) ? reviews_array : []
        write_attribute(:negative_reviews, reviews_array)
      end

      def max_time
        reviews.empty? ? 0 : reviews.max
      end

      def min_time
        reviews.empty? ? 0 : reviews.min
      end

      def average_time_positive
        reviews_average_time positive_reviews
      end

      def average_time_negative
        reviews_average_time negative_reviews
      end

      def average_time
        reviews_average_time reviews
      end

      def playtime_deviation
        if self.reviews.empty?
          nil
        else
          avg = average_time
          p = PLAYTIME_DEVIATION_PERCENTAGE
          reviews.select{|x| x < avg*(1+p) and x > avg*(1-p)}.size / Float(reviews.size)
          # Math.sqrt(self.reviews.map{|x| x**2}.reduce(:+) / self.reviews.size) / average_time - 1
        end
      end

      OS_FLAGS = {
        win: 0b001,
        mac: 0b010,
        linux: 0b100
      }

      flags_attribute :os, :os_flags

      FEATURES_FLAGS = {
        single_player: 0b1,
        multi_player: 0b10,               #
        co_op: 0b100,
        achievements: 0b1000,             #
        cloud: 0b10000,
        cards: 0b100000,                  #
        controller: 0b1000000,            #
        partial_controller: 0b10000000,   #
        stats: 0b100000000,               #
        workshop: 0b1000000000,           #
        captions: 0b10000000000,          #
        commentary: 0b100000000000,       #
        level_editor: 0b1000000000000,    #
        vac: 0b10000000000000,            #
        vr: 0b100000000000000,            #
        leaderboards: 0b1000000000000000  #
      }

      flags_attribute :features, :features_flags

      ########## Time Update Methods ##########
      #########################################

      def update_reviews!
        self.reviews_updated_at = Time.now.utc
      end

      def update_game_list!
        self.game_list_updated_at = Time.now.utc
      end

      def update_game!
        self.game_updated_at = Time.now.utc
      end

      ########## Miscenlaneous ##########
      ###################################

      def summary_attrs
        attrs = attributes.dup
        attrs.symbolize_keys!
        attrs.delete(:negative_reviews)
        attrs.delete(:positive_reviews)
        attrs.delete(:id)
        attrs.delete(:os_flags)
        attrs.delete(:features_flags)
        attrs[:positive_reviews_length] = positive_reviews.size
        attrs[:negative_reviews_length] = negative_reviews.size
        attrs[:min_time] = min_time
        attrs[:max_time] = max_time
        attrs[:average_time_positive] = (average_time_positive and reviews.size > 5)? average_time_negative.round(2) : nil
        attrs[:average_time_negative] = (average_time_negative and reviews.size > 5) ? average_time_negative.round(2) : nil
        attrs[:average_time] = (average_time and reviews.size > 5) ? average_time.round(2) : nil
        attrs[:playtime_deviation] = (playtime_deviation and reviews.size > 5) ? playtime_deviation.round(4) : nil
        attrs[:categories] = categories
        attrs[:steam_app_id] = id
        attrs[:game_updated_at] = game_updated_at.to_i*1000
        attrs[:reviews_updated_at] = reviews_updated_at.to_i*1000
        attrs[:game_list_updated_at] = game_list_updated_at.to_i*1000
        attrs[:launch_date] = launch_date.to_i*1000
        attrs[:os] = os_flags
        attrs[:features] = features_flags

        attrs
      end

      def as_json(options)
        summary_attrs
      end

      ########## Private helpers ##########
      #####################################
      private

      def reviews_average_time(reviews)
        if reviews.empty?
          0
        else
          (reviews.reduce(:+) / Float(reviews.size)).round(2)
        end
      end
    end
  end
end