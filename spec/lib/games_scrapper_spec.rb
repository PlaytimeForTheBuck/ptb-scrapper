require 'spec_helper'

describe GamesScrapper do
  def fixture(name)
    file_name = File.expand_path("../../fixtures/#{name}.html", __FILE__)
    File.read file_name
  end

  def stub_page(url, name)
    web_content = fixture name
    stub_request(:get, url).to_return body: web_content
  end

  describe '#new' do
    it 'should be created with a list of previous games' do
      games = [Game.new, Game.new, Game.new]
      GamesScrapper.new games
    end
  end

  describe '#scrap' do
    context 'all games are new' do
      it 'should create each game' do
        stub_page GamesScrapper.url, 'games_single_page'
        scrapper = GamesScrapper.new []
        scrapper.scrap
        scrapper.subjects.size.should eq 25
      end
    end

    context 'all games already exist' do
      it 'should update all previous games' do 
        stub_page GamesScrapper.url, 'games_single_page'
        scrapper = GamesScrapper.new []
        scrapper.scrap
        scrapper.subjects.size.should eq 25
        scrapper.subjects[1].price = 9999
        scrapper.subjects[1].sale_price = 99
        scrapper.scrap
        scrapper.subjects[1].price.should eq 6.99
        scrapper.subjects[1].sale_price.should eq 4.89
      end
    end

    context 'some games exist and some do not' do
      it 'should update the existing games and create the new games' do
        stub_page GamesScrapper.url, 'games_single_page'
        game = build :game, steam_app_id: 12520
        scrapper = GamesScrapper.new [game]
        scrapper.scrap
        scrapper.subjects.size.should eq 25
        game.name.should eq '18 Wheels of Steel: American Long Haul'
      end

      it 'should update the game_updated_at of all the games' do
        stub_page GamesScrapper.url, 'games_single_page'
        game = build :game, steam_app_id: 12520
        scrapper = GamesScrapper.new [game]
        game.game_updated_at.should eq nil
        time_now = Time.now
        scrapper.scrap
        game.game_updated_at.should > time_now
      end
    end

    context 'game is found' do
      subject :game do
        stub_page GamesScrapper.url, 'games_single_page'
        scrapper = GamesScrapper.new []
        scrapper.scrap
        scrapper.subjects.first
      end

      it { game.name.should eq '1... 2... 3... KICK IT! (Drop That Beat Like an Ugly Baby)' }
      it { game.steam_app_id.should eq 15540 }
      it { game.launch_date.should eq Time.parse('12 Jan 2013') }
      it { game.meta_score.should eq 44 }
      it { game.price.should eq 9.99 }
      it { game.sale_price.should eq nil }
    end

     context 'game on sale is found' do
      subject :game do
        stub_page GamesScrapper.url, 'games_single_page'
        scrapper = GamesScrapper.new []
        scrapper.scrap
        scrapper.subjects[1]
      end

      it { game.price.should eq 6.99 }
      it { game.sale_price.should eq 4.89 }
    end

    context 'game with weird free price markup' do
      it 'should not raise any error with play for free!' do
        stub_page GamesScrapper.url, 'games_page_32_with_conflicting_html'
        scrapper = GamesScrapper.new []
        scrapper.scrap
        scrapper.subjects.size.should eq 24
      end

      it 'should not raise any error with Third-party' do
         stub_page GamesScrapper.url, 'games_single_page_third_party_price'
          scrapper = GamesScrapper.new []
          scrapper.scrap
          scrapper.subjects.size.should eq 25
      end
    end

    context 'cannot connect to the server' do
      it 'should raise an exception' do
        stub_request(:get, GamesScrapper.url).to_raise Timeout::Error
        scrapper = GamesScrapper.new []
        ->{ scrapper.scrap }.should raise_error GamesScrapper::NoServerConnection
      end
    end

    context 'HTML structure is invalid' do
      def should_be_invalid
        scrapper = GamesScrapper.new []
        ->{ scrapper.scrap }.should raise_error GamesScrapper::InvalidHTML
      end

      context 'price sales change strike with span' do
        it 'should raise an exception' do
          stub_page GamesScrapper.url, 'games_single_page_invalid_strike_to_span'
          should_be_invalid
        end
      end

      context 'title changes from h4 to h3' do
        it 'should raise an exception' do
          stub_page GamesScrapper.url, 'games_single_page_invalid_h4_to_h3'
          should_be_invalid
        end
      end

      context 'changes the steam app id location' do
        it 'should raise an exception' do
          stub_page GamesScrapper.url, 'games_single_page_invalid_wrong_steam_app_id_location'
          should_be_invalid
        end
      end
    end

    context 'there are many pages' do
      it 'should get games from every page' do
        stub_page GamesScrapper.url(1), 'games_page_1'
        stub_page GamesScrapper.url(2), 'games_page_2'
        stub_page GamesScrapper.url(3), 'games_page_3'

        scrapper = GamesScrapper.new []
        scrapper.scrap
        scrapper.subjects.size.should eq 75
      end
    end

    it 'should ignore games that are invalid' do
      stub_page GamesScrapper.url(1), 'games_single_page_invalid_game' 
      scrapper = GamesScrapper.new []

      # Games with no price -> Ignored
      # Games not released -> Ignored
      # Games with an unespecific release date -> Ignored
      # Demos -> Ignored
      scrapper.scrap
      scrapper.subjects.size.should eq 22
    end

    it 'should call the given block for every request with the scrapped games' do
      stub_page GamesScrapper.url(1), 'games_page_1'
      stub_page GamesScrapper.url(2), 'games_page_2'
      stub_page GamesScrapper.url(3), 'games_single_page_invalid_game'

      scrapper = GamesScrapper.new []
      expect { |b| scrapper.scrap(&b) }.to yield_control.exactly(3).times
    end
  end

  describe '#games' do
    it 'should give the list of games that was given to it' do
      games = [Game.new, Game.new]
      scrapper = GamesScrapper.new games
      scrapper.subjects.should eq games
    end
  end
end