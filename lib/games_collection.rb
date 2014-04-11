require 'json'

# I was going to use this, but I endend up not using it. Maybe later.

class GamesCollection < Array
  attr_reader :games

  def initialize(file)
    @file = file
    read_games
  end

  def read_games
    games_attributes = @file.size >=2 ? JSON.parse(@file.read, symbolize_names: true) : []
    @games = games_attributes.map{|a| Game.new a}
  end
end