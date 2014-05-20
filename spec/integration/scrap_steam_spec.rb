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

	before :all do
		WebMock.allow_net_connect!
		# FakeFS.deactivate!
	end

	after :all do
		WebMock.disable_net_connect!
		# FakeFS.activate!
	end

  describe 'games scrapping' do
	  it 'should generate more than 40 (ideally 40) games after 2 succeful requests' do
	  	stub_page GamesScrapper.url(3), 'games_empty_page'	  	
	  	scrapper = ScrappingOverlord.new 'tmp/db', 'tmp/summary_db'
	  	scrapper.scrap_games
	  	Game.all.size.should > 40
	  end

	  it 'should save it to a json object' do
	  	stub_page GamesScrapper.url(3), 'games_empty_page'	  	
	  	scrapper = ScrappingOverlord.new 'tmp/db', 'tmp/summary_db'
	  	scrapper.scrap_games
	  	scrapper.save
	  	FileUtils.rm_rf('tmp/db')

	  	file_name = Dir.glob("tmp/db/*").last
	  	File.open file_name, 'r' do |file|
	  		games = JSON.parse(file.read, symbolize_names: true)
	  		games.size.should > 40
	  	end
	  end
	end

	describe 'reviews scrapping' do
		it 'should get all the reviewable games reviews' do
			attributes = JSON.parse(%Q({"average_time_negative":0,"average_time_positive":0,"array_positive_reviews":[],"array_negative_reviews":[],"meta_score":null,"price":7.99,"sale_price":null,"launch_date":"2014-04-03 00:00:00 -0300","reviews_updated_at":null,"game_updated_at":"2014-04-23 21:21:45 -0300","name":"Team Fortress 2","steam_app_id":440}), symbolize_names: true);
			game = Game.new attributes
			Game.should_receive(:get_for_reviews_updating).and_return([game]);
			stub_request(:get, ReviewsScrapper.url(440, 3)).to_return body: ''
			scrapper = ScrappingOverlord.new 'tmp/db', 'tmp/summary_db'
			scrapper.scrap_reviews
			game.array_reviews.size.should eq 20
		end
	end
end