require 'spec_helper'

describe CategoriesScrapper do
  def fixture(name)
    file_name = File.expand_path("../../fixtures/#{name}.html", __FILE__)
    File.read file_name
  end

  def stub_page(url, name)
    web_content = fixture name
    stub_request(:get, url).to_return body: web_content
  end

  def stub_game_request(game, name)
    stub_page(CategoriesScrapper.url(game.steam_app_id), name)
  end

  describe '#scrap' do
    context 'valid markup' do
      it 'updates the categories of the game' do
        game = build :game
        stub_game_request(game, 'categories_valid')
        scrapper = CategoriesScrapper.new [game]
        scrapper.scrap
        game.categories.should eq ['Turn-based Strategy', 'Strategy', 'One More Turn',
                                   'Turn-based', 'Addictive', 'Multiplayer',
                                   '4X', 'Timesink', 'Historic', 'Singleplayer']
      end
    end

    context 'invalid markup' do
      it 'should raise an InvalidHTML error' do
        game = build :game
        stub_game_request(game, 'categories_invalid')
        scrapper = CategoriesScrapper.new [game]
        -> {scrapper.scrap}.should raise_error Scrapper::InvalidHTML
      end
    end

  end
end