require 'spec_helper'

# Pretty shitty and worthless tests

describe ScrappingOverlord do
  include FakeFS::SpecHelpers

  before :each do
    Log.stub :info
    Log.stub :error
    Mail::TestMailer.deliveries.clear
    GamesScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
    GamesScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
    ReviewsScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
    ReviewsScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
  end

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

    it 'should log an error if the HTML is invalid' do
      Log.should_receive(:error).with(/ERROR/i).at_least(1)
      Game.should_receive(:all).and_return([])
      GamesScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord = ScrappingOverlord.new
      overlord.scrap_games
    end

    it 'should send an email if the HTML is invalid' do
      Game.should_receive(:all).and_return([])
      GamesScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord = ScrappingOverlord.new
      Mail::TestMailer.deliveries.should be_empty
      overlord.scrap_games
      Mail::TestMailer.deliveries.should_not be_empty
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

    it 'should log an error if the HTML is invalid' do
      Log.should_receive(:error).with(/ERROR/i).at_least(1)
      Game.should_receive(:get_for_reviews_updating).and_return([])
      ReviewsScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord = ScrappingOverlord.new
      overlord.scrap_reviews
    end

    it 'should send an email if the HTML is invalid' do
      Game.should_receive(:get_for_reviews_updating).and_return([])
      ReviewsScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord = ScrappingOverlord.new
      Mail::TestMailer.deliveries.should be_empty
      overlord.scrap_reviews
      Mail::TestMailer.deliveries.should_not be_empty
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