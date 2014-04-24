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
    attr_accessor :all
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
    end

    def save_to_file
      @file.truncate 0
      @file.rewind
      @file.write @all.to_json
    end

    # Just deletes the ghetto database
    def cleanup
      @all = []
      @dataset = []
    end

    # Gets the games that need *reviews* updating
    # By the age of the game
    # the time for updating is:
    #   1 week game: 1 day
    #   1 month game: 7 days
    #   1 year game: 1 month
    #   3 years game: 3 months
    #   3+ years game: 1 year
    #
    # Maybe I'm gonna implement something like the following too:
    #
    # By the quantity of reviews, the
    # time for updating is multiplied
    # This is to not everload the server.
    #   <20 reviews: max 1 week
    #   >500 reviews: minimum 1 week
    #   >1000 reviews: minimum 3 months
    #
    # But probably not.
    def get_for_reviews_updating
      day_ago    = Time.now - 3600*24           # 1 day ago
      week_ago   = Time.now - 3600*24*7         # 1 week ago
      month_ago  = Time.now - 3600*24*30        # 1 month ago
      months_ago = Time.now - 3600*24*30*3      # 3 months ago
      year_ago   = Time.now - 3600*24*365       # 1 year ago
      years_ago  = Time.now - 3600*24*365*3     # 3 years ago

      all.select do |game|
        date     = game.reviews_updated_at
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
        else
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
     sale_price).each do |attr|

    define_method attr do 
      @attributes[attr.to_sym]
    end

    define_method "#{attr}=" do |val|
      @attributes[attr.to_sym] = val
    end
  end

  def initialize(attributes = {})
    @attributes = attributes
    init_defaults
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
    self.meta_score = meta_score
    self.price = price
    self.sale_price = sale_price
    self.launch_date = launch_date
    self.reviews_updated_at = reviews_updated_at
    self.game_updated_at = self.game_updated_at
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

  def array_positive_reviews=(val)
    @array_reviews = nil
    attributes[:array_positive_reviews] = val.kind_of?(Array) ? val : []
  end

  def array_negative_reviews=(val)
    @array_reviews = nil
    attributes[:array_negative_reviews] = val.kind_of?(Array) ? val : []
  end

  def array_reviews
    @array_reviews ||= array_positive_reviews.dup.concat array_negative_reviews
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
      if not array_reviews.empty? # I don't like unless
        calculate_average_time_positive
        calculate_average_time_negative
        calculate_average_time
        calculate_max_time
        calculate_min_time
        calculate_centiles
        calculate_positive_reviews_count
        calculate_negative_reviews_count
      end

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
    raise('Save error') if not save
  end
  alias_method :process!, :save!

  def calculate_average_time_positive
    if array_positive_reviews.empty?
      self.average_time_positive = 0
    else
      self.average_time_positive = array_positive_reviews.reduce(:+) / Float(array_positive_reviews.size)
    end
  end

  def calculate_average_time_negative
    if array_negative_reviews.empty?
      self.average_time_negative = 0
    else
      self.average_time_negative = array_negative_reviews.reduce(:+) / Float(array_negative_reviews.size)
    end
  end

  def calculate_average_time
    if array_reviews.empty?
      self.average_time = 0
    else
      self.average_time = array_reviews.reduce(:+) / Float(array_reviews.size)
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

  #################################
  ## Utilities ####################
  #################################

  def to_json(a = nil)
    JSON.generate attributes
  end

  def ==(game)
    return game.steam_app_id == steam_app_id if game.is_a?(Game)
    false
  end
end
