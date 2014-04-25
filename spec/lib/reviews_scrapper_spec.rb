require 'spec_helper'

describe ReviewsScrapper do
  def fixture(name)
    file_name = File.expand_path("../../fixtures/#{name}.html", __FILE__)
    File.read file_name
  end

  def stub_page(url, name)
    web_content = fixture name
    stub_request(:get, url).to_return body: web_content
  end

  def stub_empty(url)
    stub_request(:get, url).to_return body: ''
  end

  describe '#new' do
    it 'should be created with a list of previous games' do
      games = [Game.new, Game.new, Game.new]
      ReviewsScrapper.new games
    end
  end

  describe '#scrap' do
    it 'updates the reviews_updated_at attribute' do
      games = [Game.new, Game.new, Game.new]
      stub_empty ReviewsScrapper.url(games[0].steam_app_id)
      stub_empty ReviewsScrapper.url(games[1].steam_app_id)
      stub_empty ReviewsScrapper.url(games[2].steam_app_id)

      scrapper = ReviewsScrapper.new games
      time_now = Time.now
      scrapper.scrap
      games[0].reviews_updated_at.should > time_now
      games[1].reviews_updated_at.should > time_now
      games[2].reviews_updated_at.should > time_now
    end

    context 'there are no reviews' do
      it 'does not fill any review' do
        game = build :game
        stub_request(:get, ReviewsScrapper.url(game.steam_app_id)).to_return body: ''
        scrapper = ReviewsScrapper.new [game]
        scrapper.scrap
        game.array_positive_reviews.size.should eq 0
        game.array_negative_reviews.size.should eq 0
      end
    end

    context 'there are reviews' do
      it 'fills the reviews' do
        game = build :game
        scrapper = ReviewsScrapper.new [game]
        stub_page ReviewsScrapper.url(game.steam_app_id), 'reviews_single_page'
        stub_empty ReviewsScrapper.url(game.steam_app_id, 2)
        scrapper.scrap
        game.array_reviews.size.should eq 10
      end

      it 'ignores invalid review without played time' do
        game = build :game
        scrapper = ReviewsScrapper.new [game]
        stub_page ReviewsScrapper.url(game.steam_app_id), 'reviews_single_page_one_without_hours'
        stub_empty ReviewsScrapper.url(game.steam_app_id, 2)
        scrapper.scrap
        game.array_reviews.size.should eq 9
      end

      it 'fills the positive and negative reviews' do
        game = build :game
        scrapper = ReviewsScrapper.new [game]
        stub_page ReviewsScrapper.url(game.steam_app_id), 'reviews_single_page_3_pos_7_neg'
        stub_empty ReviewsScrapper.url(game.steam_app_id, 2)
        scrapper.scrap
        game.array_positive_reviews.size.should eq 3
        game.array_negative_reviews.size.should eq 7
      end

      it 'reads every review playtime' do
        game = build :game
        scrapper = ReviewsScrapper.new [game]
        stub_page ReviewsScrapper.url(game.steam_app_id), 'reviews_single_page_3_pos_7_neg'
        stub_empty ReviewsScrapper.url(game.steam_app_id, 2)
        scrapper.scrap
        game.array_positive_reviews[0].should eq 19.0
        game.array_positive_reviews[1].should eq 15.7
        game.array_positive_reviews[2].should eq 9.5
        game.array_negative_reviews[0].should eq 4.5
        game.array_negative_reviews[1].should eq 1.5
        game.array_negative_reviews[2].should eq 6.7
        game.array_negative_reviews[3].should eq 25.0
        game.array_negative_reviews[4].should eq 25.8
        game.array_negative_reviews[5].should eq 9.2
        game.array_negative_reviews[6].should eq 13.5
      end

      context 'an existing game with existing reviews' do
        it 'should replace the previous reviews' do
          game = build :game
          game.array_positive_reviews = [1,2,3]
          scrapper = ReviewsScrapper.new [game]
          stub_page ReviewsScrapper.url(game.steam_app_id), 'reviews_single_page'
          stub_empty ReviewsScrapper.url(game.steam_app_id, 2)
          scrapper.scrap
          game.array_reviews.size.should eq 10
        end
      end
    end

    context 'there is a review flagged as abusive' do
      it 'should ignore it' do
        game = build :game
        scrapper = ReviewsScrapper.new [game]
        stub_page ReviewsScrapper.url(game.steam_app_id), 'reviews_flagged_as_abusive'
        stub_empty ReviewsScrapper.url(game.steam_app_id, 2)
        scrapper.scrap
        game.array_reviews.size.should eq 1
      end
    end


    context 'there are many pages' do
      it 'reads the reviews from each page' do
        game = build :game
        scrapper = ReviewsScrapper.new [game]
        stub_page ReviewsScrapper.url(game.steam_app_id, 1), 'reviews_page_1'
        stub_page ReviewsScrapper.url(game.steam_app_id, 2), 'reviews_page_2'
        stub_page ReviewsScrapper.url(game.steam_app_id, 3), 'reviews_page_3'
        stub_empty ReviewsScrapper.url(game.steam_app_id, 4)
        scrapper.scrap
        game.array_reviews.size.should eq 30
      end

      it 'calls the yield block for each page' do
        game = build :game
        scrapper = ReviewsScrapper.new [game]
        stub_page ReviewsScrapper.url(game.steam_app_id, 1), 'reviews_page_1'
        stub_page ReviewsScrapper.url(game.steam_app_id, 2), 'reviews_page_2'
        stub_page ReviewsScrapper.url(game.steam_app_id, 3), 'reviews_page_3'
        stub_empty ReviewsScrapper.url(game.steam_app_id, 4)
        expect { |b| scrapper.scrap(&b) }.to yield_successive_args([game, 1], [game, 2], [game, 3])
      end
    end
  end

  describe '#games' do
    it 'should give the list of games that was given to it' do
      games = [Game.new, Game.new]
      scrapper = ReviewsScrapper.new games
      scrapper.games.should eq games
    end
  end
end