require 'spec_helper'

# Pretty shitty and worthless tests

describe ScrappingOverlord do
  include FakeFS::SpecHelpers

  before :each do
    Log.stub :info
    Log.stub :error
    Mail::TestMailer.deliveries.clear
    GamesListScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
    GamesListScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
    ReviewsScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
    ReviewsScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
    GameScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
    GameScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
  end

  let(:overlord) { ScrappingOverlord.new 'tmp/db/games.json' }


  describe '#scrap_games_list' do
    it 'loads the games from Game and calls the GamesListScrapper' do
      game = build :game_ar
      GameAr.should_receive(:all).and_return([game])
      # game.should_receive(:save!).and_return true
      GamesListScrapper.any_instance.should_receive(:scrap).and_yield([], [game], 1)
      overlord.scrap_games_list
    end

    it 'should log an error if the HTML is invalid' do
      Log.should_receive(:error).with(/ERROR/i, /http/).at_least(1)
      GameAr.should_receive(:all).and_return([])
      GamesListScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord.scrap_games_list
    end

    it 'should send an email if the HTML is invalid' do
      GameAr.should_receive(:all).and_return([])
      GamesListScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      Mail::TestMailer.deliveries.should be_empty
      overlord.scrap_games_list
      Mail::TestMailer.deliveries.should_not be_empty
    end
  end

  describe '#scrap_reviews' do # And categories
    it 'loads the games from Game and calls the ReviewsScrapper' do
      game = build :game_ar
      GameAr.should_receive(:get_for_reviews_updating).and_return([game])
      # game.should_receive(:save!).and_return true
      ReviewsScrapper.any_instance.should_receive(:scrap).and_yield(game, {positive: [1], negative: [1]}, true)
      overlord.scrap_reviews
    end

    it 'should log an error if the HTML is invalid' do
      Log.should_receive(:error).with(/ERROR/i, /http/).at_least(1)
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
    it 'loads the games from Game and calls GameScrapper' do
      game = build :game_ar
      GameAr.should_receive(:get_for_games_updating).and_return [game]
      # game.should_receive(:save!).and_return true
      GameScrapper.any_instance.should_receive(:scrap).and_yield(game)
      overlord.scrap_games
    end

    it 'loads the games from Game and calls GameScrapper' do
      Log.should_receive(:error).with(/ERROR/i, /http/).at_least(1)
      GameAr.should_receive(:get_for_games_updating).and_return([])
      GameScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      overlord.scrap_games
    end

    it 'should send an email if the HTML is invalid' do
      GameAr.should_receive(:get_for_games_updating).and_return([])
      GameScrapper.any_instance.should_receive(:scrap).and_raise(Scrapper::InvalidHTML)
      Mail::TestMailer.deliveries.should be_empty
      overlord.scrap_games
      Mail::TestMailer.deliveries.should_not be_empty
    end
  end
end