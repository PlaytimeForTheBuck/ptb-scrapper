require 'json'
require 'time'

class Game
  ################################
  ## Class methods ###############
  ################################

  # TODO:
  # I should probably extract this
  # databasey/collections thingy to another
  # class. Or just use an AR and SQLite
  # or something like that.

  # @@dataset has a list of `#save`d Game attributes hashes
  @dataset = []

  # @@all has a list of `#save`d Game objects
  @all = []

  class << self 
    attr_accessor :all, :to_summary_json
    alias_method :to_summary_json?, :to_summary_json 
    attr_reader :dataset
 
    # Creates a Game for each hash in data_hashes
    # And it adds them to @@all and @@dataset
    def set_dataset(data_hashes)
      cleanup
      @dataset = data_hashes
      data_hashes.each do |data|
        self.all.push Game.new(data)
      end
    end

    # Sets a file to use as a ghetto database
    def set_file(file)
      @file = file
      attributes = @file.size >= 2 ? JSON.parse(@file.read, symbolize_names: true) : []
      set_dataset(attributes)
      Log.info 'Games file parsed'
    end

    def save_to_file
      @file.truncate 0
      @file.rewind
      @file.write @all.to_json
      Log.info 'Saved to file'
    end

    def save_summary_to_file(file)
      @to_summary_json = true
      file.truncate 0
      file.rewind
      file.write @all.to_json
      @to_summary_json = false
      Log.info 'Saved summary to file'
    end

    # Just deletes the ghetto database
    def cleanup
      @all = []
      @dataset = []
    end

    def get_for_reviews_updating
      get_for_x_updating(:reviews_updated_at)
    end

    def get_for_categories_updating
      get_for_x_updating(:categories_updated_at)
    end

    # Gets the games that need an update based on a last updated_at attribute
    # By the age of the game
    # the time for updating is:
    #   1 week game: 1 day
    #   1 month game: 7 days
    #   1 year game: 1 month
    #   3 years game: 3 months
    #   3+ years game: 1 year
    def get_for_x_updating(updated_at_attribute)
      day_ago    = Time.now - 3600*24           # 1 day ago
      week_ago   = Time.now - 3600*24*7         # 1 week ago
      month_ago  = Time.now - 3600*24*30        # 1 month ago
      months_ago = Time.now - 3600*24*30*3      # 3 months ago
      year_ago   = Time.now - 3600*24*365       # 1 year ago
      years_ago  = Time.now - 3600*24*365*3     # 3 years ago

      all.select do |game|
        date     = game.attributes[updated_at_attribute]
        # If no launch date we treat it like a year ago
        launched = game.launch_date ? game.launch_date : year_ago

        # The game was never updated?
        if date == nil
          true
        # Launched less than a week ago?
        elsif launched > week_ago
          # Updated more than a day ago?
          date < day_ago
        # Launched less than a month ago?
        elsif launched > month_ago
          # Updated more than a week ago?
          date < week_ago
        # Launched less than a year ago?
        elsif launched > year_ago 
          # Updated more than a month ago?
          date < month_ago
        # Launched less than 3 years ago?
        elsif launched > years_ago
          # Updated more than 3 months ago
          date < months_ago
        else # Launched more than 3 years ago?
          # Updated more than a year ago
          date < year_ago
        end
      end
    end
  end

  ################################
  ## Attributes ##################
  ################################

  attr_accessor :attributes, :array_reviews

  # Data attributes
  %w(name 
     steam_app_id 
     launch_date 
     meta_score 
     average_time 
     average_time_positive
     average_time_negative
     max_time
     min_time
     reviews_centile_1
     reviews_centile_2
     reviews_centile_3
     reviews_centile_4
     reviews_centile_5
     positive_reviews
     negative_reviews
     array_positive_reviews
     array_negative_reviews
     price
     reviews_updated_at
     game_updated_at
     categories_updated_at
     sale_price
     categories
     playtime_deviation).each do |attr|

    define_method attr do
      @attributes[attr.to_sym]
    end

    define_method "#{attr}=" do |val|
      @attributes[attr.to_sym] = val
    end
  end

  def initialize(attributes = {})
    @attributes = attributes
    Log.debug @attributes.inspect
    init_defaults
  end

  def id
    attributes[:steam_app_id]
  end

  ################################
  ## Validations #################
  ################################

  def valid?
    if self.name.blank? or
    self.steam_app_id.blank? or
    # self.price.blank? or
    # self.launch_date.blank? or
    not array_positive_reviews.all_numeric? or
    not array_negative_reviews.all_numeric?
      false
    else
      true
    end
  end

  #################################
  ## More Attributes ##############
  #################################

  def init_defaults
    @array_reviews = []
    self.average_time_negative ||= 0
    self.average_time_positive ||= 0
    self.array_positive_reviews ||= []
    self.array_negative_reviews ||= []
    self.categories ||= nil
    self.meta_score = meta_score
    self.price = price
    self.sale_price = sale_price
    self.launch_date = launch_date
    self.reviews_updated_at = reviews_updated_at
    self.game_updated_at = self.game_updated_at
    self.categories_updated_at = self.categories_updated_at
  end

  def meta_score=(val)
    attributes[:meta_score] = val.blank? ? nil : Integer(val)
  end

  def price=(val)
    attributes[:price] = val.blank? ? nil : Float(val)
  end

  def sale_price=(val)
    attributes[:sale_price] = val.blank? ? nil : Float(val)
  end

  def launch_date=(val)
    attributes[:launch_date] = if val.blank?
      nil
    else
      val.is_a?(String) ? Time.parse(val) : val
    end
  end

  def reviews_updated_at=(val)
    attributes[:reviews_updated_at] = if val.blank?
      nil
    else
      val.is_a?(String) ? Time.parse(val) : val
    end
  end
  
  def game_updated_at=(val)
    attributes[:game_updated_at] = if val.blank?
      nil
    else
      val.is_a?(String) ? Time.parse(val) : val
    end
  end

  def categories_updated_at=(val)
    attributes[:categories_updated_at] = if val.blank?
      nil
    else
      val.is_a?(String) ? Time.parse(val) : val
    end
  end

  def array_positive_reviews=(val)
    @array_reviews = nil
    attributes[:array_positive_reviews] = val.kind_of?(Array) ? val : []
  end

  def array_negative_reviews=(val)
    @array_reviews = nil
    attributes[:array_negative_reviews] = val.kind_of?(Array) ? val : []
  end

  def categories=(arr)
    attributes[:categories] = arr[0...10] if not arr.nil?
  end

  def array_reviews
    array_positive_reviews.dup.concat array_negative_reviews
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

  #################################
  ## Saving and loading ###########
  #################################

  def update_reviews!
    self.reviews_updated_at = Time.now
  end

  def update_game!
    self.game_updated_at = Time.now
  end

  def update_categories!
    self.categories_updated_at = Time.now
  end

  # We actually have more saving and loading
  # but it's on the class. (up top)

  #################################
  ## Callbacks ####################
  #################################

  # Returns false if game is valid
  # Returns true if game is invalid
  # If game is valid recalculate all the things
  # If game is valid adds it to the @@dataset
  def save
    if valid?
      # if not array_reviews.empty? # I don't like unless
        calculate_average_time_positive
        calculate_average_time_negative
        calculate_average_time
        calculate_max_time
        calculate_min_time
        calculate_centiles
        calculate_positive_reviews_count
        calculate_negative_reviews_count
        calculate_playtime_deviation
      # end

      # Now we add them to the "database" of games

      if not Game.dataset.find_index attributes
        Game.dataset.push attributes
      end

      if not Game.all.find_index self
        Game.all.push self
      end
      true
    else
      false
    end
  end
  alias_method :process, :save

  def save!
    if not save
      raise('Save error')
    end
  end
  alias_method :process!, :save!

  def calculate_average_time_positive
    if array_positive_reviews.empty?
      self.average_time_positive = 0
    else
      self.average_time_positive = (array_positive_reviews.reduce(:+) / Float(array_positive_reviews.size)).round(2)
    end
  end

  def calculate_average_time_negative
    if array_negative_reviews.empty?
      self.average_time_negative = 0
    else
      self.average_time_negative = (array_negative_reviews.reduce(:+) / Float(array_negative_reviews.size)).round(2)
    end
  end

  def calculate_average_time
    if array_reviews.empty?
      self.average_time = 0
    else
      self.average_time = (array_reviews.reduce(:+) / Float(array_reviews.size)).round(2)
    end
  end

  def calculate_max_time
    self.max_time = array_reviews.empty? ? 0 : array_reviews.max
  end

  def calculate_min_time
    self.min_time = array_reviews.empty? ? 0 : array_reviews.min
  end

  def calculate_centiles
    self.reviews_centile_1 = array_reviews.centile 1
    self.reviews_centile_2 = array_reviews.centile 2
    self.reviews_centile_3 = array_reviews.centile 3
    self.reviews_centile_4 = array_reviews.centile 4
    self.reviews_centile_5 = array_reviews.centile 5
  end

  def calculate_positive_reviews_count
    self.positive_reviews = array_positive_reviews.size
  end

  def calculate_negative_reviews_count
    self.negative_reviews = array_negative_reviews.size
  end

  def calculate_playtime_deviation
    if self.array_reviews.empty?
      self.playtime_deviation = nil
    else
      self.playtime_deviation = Math.sqrt(self.array_reviews.map{|x| x**2}.reduce(:+) / self.array_reviews.size)
    end
  end

  #################################
  ## Utilities ####################
  #################################

  def as_json(options)
    if Game.to_summary_json?
      summary_attrs
    else
      attributes
    end
  end

  def summary_attrs
    attrs = attributes.dup
    attrs.delete(:array_negative_reviews)
    attrs.delete(:array_positive_reviews)
    attrs.delete(:reviews_centile_1)
    attrs.delete(:reviews_centile_2)
    attrs.delete(:reviews_centile_3)
    attrs.delete(:reviews_centile_4)
    attrs.delete(:reviews_centile_5)

    # attrs[:playtime_deviation_percentage] = ((attrs[:playtime_deviation] / attrs[:average_time] - 1) * 100).floor / 100

    if not attrs[:game_updated_at].nil?
      attrs[:game_updated_at] = (attrs[:game_updated_at].to_f * 1000).truncate
    end

    if not attrs[:reviews_updated_at].nil?
      attrs[:reviews_updated_at] = (attrs[:reviews_updated_at].to_f * 1000).truncate
    end

    if not attrs[:launch_date].nil?
      attrs[:launch_date] = (attrs[:launch_date].to_f * 1000).truncate
    end

    attrs
  end

  def ==(game)
    return game.steam_app_id == steam_app_id if game.is_a?(Game)
    false
  end
end
