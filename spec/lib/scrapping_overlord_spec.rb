require 'spec_helper'

# Pretty shitty and worthless tests

describe ScrappingOverlord do
  include FakeFS::SpecHelpers

  describe '#new' do
    it 'sets the file for Game' do
      Game.should_receive(:set_file).with a_kind_of File
      ScrappingOverlord.new
    end
  end

  describe '#scrap_games' do
    it 'loads the games from Game and calls the GamesScrapper' do
      game = build :game
      Game.should_receive(:all).and_return([game])
      GamesScrapper.any_instance.should_receive(:scrap)
      overlord = ScrappingOverlord.new
      overlord.scrap_games
    end
  end

  describe '#scrap_reviews' do
    it 'loads the games from Game and calls the ReviewsScrapper' do
      game = build :game
      Game.should_receive(:get_for_reviews_updating).and_return([game])
      ReviewsScrapper.any_instance.should_receive(:scrap)
      overlord = ScrappingOverlord.new
      overlord.scrap_reviews
    end
  end
   
  describe '#save' do
    it 'calls save on each Game and then it calls save_to_file' do
      game = build :game
      Game.should_receive(:all).and_return([game])
      game.should_receive(:save).and_return true
      Game.should_receive :save_to_file
      overlord = ScrappingOverlord.new
      overlord.save
    end
  end
end