require 'spec_helper'

describe 'scrap the real thing' do
  def fixture(name)
    file_name = File.expand_path("../../fixtures/#{name}.html", __FILE__)
    File.read file_name
  end

  def stub_page(url, name)
    web_content = fixture name
    stub_request(:get, url).to_return body: web_content
  end

  let(:scrapper) { ScrappingOverlord.new 'tmp/db/games.json' }

	before :all do
		# WebMock.allow_net_connect!
		# FakeFS.deactivate!
	end

	after :all do
		# WebMock.disable_net_connect!
		# FakeFS.activate!
	end

	after :each do
		# FileUtils.rm_rf('tmp/db')
	end

  describe 'games scrapping' do
  	before :each do
  		stub_page GamesListScrapper.url(1), 'games_steam_spec_1'
	  	stub_page GamesListScrapper.url(2), 'games_steam_spec_2'
	  	stub_page GamesListScrapper.url(3), 'games_empty_page'	
  	end

	  it 'should generate (ideally) 50 games after 2 succeful requests' do
	  	games = scrapper.scrap_games_list(false)
	  	games.size.should eq 50
	  end

	  it 'should save it to a the DB' do  	
	  	scrapper.scrap_games_list(true)
	  	GameAr.all.size.should eq 50
	  end
	end

	describe 'reviews scrapping' do
		it 'should get all the reviewable games reviews' do
			game = build :game_ar
			game.steam_app_id = 440
			GameAr.should_receive(:get_for_reviews_updating).and_return([game]);
			stub_page ReviewsScrapper.url(440, 1), 'reviews_steam_spec_1'
			stub_page ReviewsScrapper.url(440, 2), 'reviews_steam_spec_1'
			stub_request(:get, ReviewsScrapper.url(440, 3)).to_return body: ''
			scrapper.scrap_reviews(true)
			GameAr.all.size.should eq 1
			GameAr.first.reviews.size.should eq 20
		end
	end
end