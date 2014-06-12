require 'spec_helper'

# Pretty shitty and worthless tests

module PtbScrapper
  describe ScrappingOverlord do
    include FakeFS::SpecHelpers

    before :each do
      Logger.logger.stub :info
      Logger.logger.stub :error
      Mail::TestMailer.deliveries.clear
      Scrappers::GamesListScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
      Scrappers::GamesListScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
      Scrappers::ReviewsScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
      Scrappers::ReviewsScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
      Scrappers::GameScrapper.any_instance.stub(:last_page).and_return '<html>Wow</html>'
      Scrappers::GameScrapper.any_instance.stub(:last_page_url).and_return 'http://localhost.tuvieja'
    end

    let(:overlord) { ScrappingOverlord.new 'tmp/db/games.json' }


    describe '#scrap_games_list' do
      it 'loads the games from Game and calls the GamesListScrapper' do
        game = build :game_ar
        Models::GameAr.should_receive(:all).and_return([game])
        # game.should_receive(:save!).and_return true
        Scrappers::GamesListScrapper.any_instance.should_receive(:scrap).and_yield([], [game], 1)
        overlord.scrap_games_list
      end

      it 'should log an error if the HTML is invalid' do
        Logger.logger.should_receive(:error).with(/ERROR/i, /http/).at_least(1)
        Models::GameAr.should_receive(:all).and_return([])
        Scrappers::GamesListScrapper.any_instance.should_receive(:scrap).and_raise(Scrappers::InvalidHTML)
        overlord.scrap_games_list
      end

      it 'should send an email if the HTML is invalid' do
        Models::GameAr.should_receive(:all).and_return([])
        Scrappers::GamesListScrapper.any_instance.should_receive(:scrap).and_raise(Scrappers::InvalidHTML)
        Mail::TestMailer.deliveries.should be_empty
        overlord.scrap_games_list
        Mail::TestMailer.deliveries.should_not be_empty
      end
    end

    describe '#scrap_reviews' do # And categories
      it 'loads the games from Game and calls the ReviewsScrapper' do
        game = build :game_ar
        Models::GameAr.should_receive(:get_for_reviews_updating).and_return([game])
        # game.should_receive(:save!).and_return true
        Scrappers::ReviewsScrapper.any_instance.should_receive(:scrap).and_yield(game, {positive: [1], negative: [1]}, true)
        overlord.scrap_reviews
      end

      context 'an error occurs' do
        it 'should log an error if the HTML is invalid' do
          Logger.logger.should_receive(:error).with(/ERROR/i, /http/).at_least(1)
          Models::GameAr.should_receive(:get_for_reviews_updating).and_return([])
          Scrappers::ReviewsScrapper.any_instance.should_receive(:scrap).and_raise(Scrappers::InvalidHTML)
          overlord.scrap_reviews
        end

        it 'should send an email if the HTML is invalid' do
          Models::GameAr.should_receive(:get_for_reviews_updating).and_return([])
          Scrappers::ReviewsScrapper.any_instance.should_receive(:scrap).and_raise(Scrappers::InvalidHTML)
          Mail::TestMailer.deliveries.should be_empty
          overlord.scrap_reviews
          Mail::TestMailer.deliveries.should_not be_empty
        end

        it 'should send an email from the configured email' do
          Models::GameAr.should_receive(:get_for_reviews_updating).and_return([])
          Scrappers::ReviewsScrapper.any_instance.should_receive(:scrap).and_raise(Scrappers::InvalidHTML)
          Mail::TestMailer.deliveries.should be_empty
          PtbScrapper.setup do |config|
            config.notifications_email_from = 'foo@bar.com'
          end
          overlord.scrap_reviews
          Mail::TestMailer.deliveries.first.from.should eq ['foo@bar.com']
        end

        it 'should send an email to the configured email' do
          Models::GameAr.should_receive(:get_for_reviews_updating).and_return([])
          Scrappers::ReviewsScrapper.any_instance.should_receive(:scrap).and_raise(Scrappers::InvalidHTML)
          Mail::TestMailer.deliveries.should be_empty
          PtbScrapper.setup do |config|
            config.notifications_email_to = 'foo@bar.com'
          end
          overlord.scrap_reviews
          Mail::TestMailer.deliveries.first.to.should eq ['foo@bar.com']
        end
      end
    end

    describe '#scrap_categories' do
      it 'loads the games from Game and calls GameScrapper' do
        game = build :game_ar
        Models::GameAr.should_receive(:get_for_games_updating).and_return [game]
        # game.should_receive(:save!).and_return true
        Scrappers::GameScrapper.any_instance.should_receive(:scrap).and_yield(game)
        overlord.scrap_games
      end

      it 'loads the games from Game and calls GameScrapper' do
        Logger.logger.should_receive(:error).with(/ERROR.*http/).at_least(1)
        Models::GameAr.should_receive(:get_for_games_updating).and_return([])
        Scrappers::GameScrapper.any_instance.should_receive(:scrap).and_raise(Scrappers::InvalidHTML.new('MahError', 'http://caca.com', '<html></html>'))
        overlord.scrap_games
      end

      it 'should send an email if the HTML is invalid' do
        Models::GameAr.should_receive(:get_for_games_updating).and_return([])
        Scrappers::GameScrapper.any_instance.should_receive(:scrap).and_raise(Scrappers::InvalidHTML.new('MahError', 'http://caca.com', '<html></html>'))
        Mail::TestMailer.deliveries.should be_empty
        overlord.scrap_games
        Mail::TestMailer.deliveries.should_not be_empty
      end
    end

    describe '#create_summary' do 
      def read_summary_file
        JSON.parse File.read('tmp/db/games.json'), symbolize_names: true
      end

      def jsonized_attrs(games)
        JSON.parse games.to_json, symbolize_names: true
      end

      it 'should generate the summary file' do
        games = []
        games << build(:game_ar)
        games << build(:game_ar)
        games << build(:game_ar)
        Models::GameAr.should_receive(:get_for_summary).and_return(games)
        overlord.create_summary
        file_attr = read_summary_file
        games_attr = jsonized_attrs games
        file_attr[:games].size.should eq games_attr.size
        # Gonna add it as soon as I separate the camelize method, mucha paja
        # I'm testing them below this one anyway
        # file_attr[:osFlags].should eq Models::GameAr::OS_FLAGS
        # file_attr[:featuresFlags].should eq Models::GameAr::FEATURES_FLAGS
      end

      it 'should generate all the games keys camelized' do
        games = []
        games << build(:game_ar)
        games << build(:game_ar)
        games << build(:game_ar)
        Models::GameAr.should_receive(:get_for_summary).and_return(games)
        overlord.create_summary
        file_attr = read_summary_file
        # We sample the data, 'cause I don't wanna write every single attribute
        file_attr[:games][0][:steamAppId].should eq games[0].steam_app_id
        file_attr[:games][1][:maxTime].should eq games[1].max_time
        file_attr[:games][2][:playtimeDeviation].should eq games[2].playtime_deviation
      end

      it 'should camelize the flags' do
        games = []
        games << build(:game_ar)
        games << build(:game_ar)
        games << build(:game_ar)
        Models::GameAr.should_receive(:get_for_summary).and_return(games)
        overlord.create_summary
        file_attr = read_summary_file
        file_attr[:featuresFlags].each_key.all?{|flag| flag =~ /^[^_]+$/}.should eq true
        file_attr[:osFlags].each_key.all?{|flag| flag =~ /^[^_]+$/}.should eq true
      end
    end
  end
end