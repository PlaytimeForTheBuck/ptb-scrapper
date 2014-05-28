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
    CategoriesScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
    CategoriesScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
  end

  let(:overlord) { ScrappingOverlord.new 'tmp/db/games.json' }


  describe '#scrap_games' do
    it 'loads the games from Game and calls the GamesScrapper' do
      game = build :game_ar
      GameAr.should_receive(:all).and_return([game])
      game.should_receive(:save!).and_return true
      GamesScrapper.any_instance.should_receive(:scrap)
      overlord.scrap_games
    end

    it 'should log an error if the HTML is invalid' do
      Log.should_receive(:error).with(/ERROR/i).at_least(1)
      GameAr.should_receive(:all).and_return([])
      GamesScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord.scrap_games
    end

    it 'should send an email if the HTML is invalid' do
      GameAr.should_receive(:all).and_return([])
      GamesScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      Mail::TestMailer.deliveries.should be_empty
      overlord.scrap_games
      Mail::TestMailer.deliveries.should_not be_empty
    end
  end

  describe '#scrap_reviews' do # And categories
    it 'loads the games from Game and calls the ReviewsScrapper' do
      game = build :game_ar
      GameAr.should_receive(:get_for_reviews_updating).and_return([game])
      game.should_receive(:save!).and_return true
      ReviewsScrapper.any_instance.should_receive(:scrap)
      overlord.scrap_reviews
    end

    it 'should log an error if the HTML is invalid' do
      Log.should_receive(:error).with(/ERROR/i).at_least(1)
      GameAr.should_receive(:get_for_reviews_updating).and_return([])
      ReviewsScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord.scrap_reviews
    end

    it 'should send an email if the HTML is invalid' do
      GameAr.should_receive(:get_for_reviews_updating).and_return([])
      ReviewsScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      Mail::TestMailer.deliveries.should be_empty
      overlord.scrap_reviews
      Mail::TestMailer.deliveries.should_not be_empty
    end
  end

  describe '#scrap_categories' do
    it 'loads the games from Game and calls CategoriesScrapper' do
      game = build :game_ar
      GameAr.should_receive(:get_for_games_updating).and_return [game]
      game.should_receive(:save!).and_return true
      CategoriesScrapper.any_instance.should_receive(:scrap)
      overlord.scrap_categories
    end

    it 'loads the games from Game and calls CategoriesScrapper' do
      Log.should_receive(:error).with(/ERROR/i).at_least(1)
      GameAr.should_receive(:get_for_games_updating).and_return([])
      CategoriesScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord.scrap_categories
    end

    it 'should send an email if the HTML is invalid' do
      GameAr.should_receive(:get_for_games_updating).and_return([])
      CategoriesScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      Mail::TestMailer.deliveries.should be_empty
      overlord.scrap_categories
      Mail::TestMailer.deliveries.should_not be_empty
    end
  end
end