require 'spec_helper'

describe GamesCollection do
  it 'should be kind of an array' do
    GamesCollection.new(StringIO.new).should be_kind_of Array
  end

  describe '#new' do
    it 'accepts a file as an argument' do 
      file = StringIO.new '[]'
      GamesCollection.new(file)
    end

    it 'reads the contents of the files as Games' do
      game1 = build :game
      game2 = build :game
      file = StringIO.new [game1, game2].to_json
      GamesCollection.new(file).games.should eq [game1, game2] 
    end
  end

  # describe '#save' do
  #   it 'calls the save method on all games'
  #   it 'saves the games on disk'
  #   it 'renames the disk the old disk file'
  # end

  # describe '#[]' do
  #   it 'should access the games as if it was an array'
  # end
end