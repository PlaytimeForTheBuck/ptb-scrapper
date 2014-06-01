require 'spec_helper'

describe PtbScrapper::Scrappers::ReviewsScrapper do
  let(:klass) { PtbScrapper::Scrappers::ReviewsScrapper }

  def build_scrapper(games)
    klass.new(games, PtbScrapper::Models::GameAr)
  end

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
      games = [build(:game_ar), build(:game_ar), build(:game_ar)]
      build_scrapper games
    end
  end

  describe '#scrap' do
    it 'updates the reviews_updated_at attribute' do
      games = [build(:game_ar), build(:game_ar), build(:game_ar)]
      stub_empty klass.url(games[0].steam_app_id)
      stub_empty klass.url(games[1].steam_app_id)
      stub_empty klass.url(games[2].steam_app_id)

      scrapper = build_scrapper games
      time_now = Time.now
      scrapper.scrap
      games[0].reviews_updated_at.should > time_now
      games[1].reviews_updated_at.should > time_now
      games[2].reviews_updated_at.should > time_now
    end

    context 'there are no reviews' do
      it 'does not fill any review' do
        game = build :game_ar
        stub_request(:get, klass.url(game.steam_app_id)).to_return body: ''
        scrapper = build_scrapper [game]
        scrapper.scrap
        game.positive_reviews.size.should eq 0
        game.negative_reviews.size.should eq 0
      end
    end

    context 'there are reviews' do
      it 'fills the reviews' do
        game = build :game_ar
        scrapper = build_scrapper [game]
        stub_page klass.url(game.steam_app_id), 'reviews_single_page'
        stub_empty klass.url(game.steam_app_id, 2)
        scrapper.scrap
        game.reviews.size.should eq 10
      end

      it 'ignores invalid review without played time' do
        game = build :game_ar
        scrapper = build_scrapper [game]
        stub_page klass.url(game.steam_app_id), 'reviews_single_page_one_without_hours'
        stub_empty klass.url(game.steam_app_id, 2)
        scrapper.scrap
        game.reviews.size.should eq 9
      end

      it 'fills the positive and negative reviews' do
        game = build :game_ar
        scrapper = build_scrapper [game]
        stub_page klass.url(game.steam_app_id), 'reviews_single_page_3_pos_7_neg'
        stub_empty klass.url(game.steam_app_id, 2)
        scrapper.scrap
        game.positive_reviews.size.should eq 3
        game.negative_reviews.size.should eq 7
      end

      it 'reads every review playtime' do
        game = build :game_ar
        scrapper = build_scrapper [game]
        stub_page klass.url(game.steam_app_id), 'reviews_single_page_3_pos_7_neg'
        stub_empty klass.url(game.steam_app_id, 2)
        scrapper.scrap
        game.positive_reviews[0].should eq 19.0
        game.positive_reviews[1].should eq 15.7
        game.positive_reviews[2].should eq 9.5
        game.negative_reviews[0].should eq 4.5
        game.negative_reviews[1].should eq 1.5
        game.negative_reviews[2].should eq 6.7
        game.negative_reviews[3].should eq 25.0
        game.negative_reviews[4].should eq 25.8
        game.negative_reviews[5].should eq 9.2
        game.negative_reviews[6].should eq 13.5
      end

      context 'an existing game with existing reviews' do
        it 'should replace the previous reviews' do
          game = build :game_ar
          game.positive_reviews = [1,2,3]
          scrapper = build_scrapper [game]
          stub_page klass.url(game.steam_app_id), 'reviews_single_page'
          stub_empty klass.url(game.steam_app_id, 2)
          scrapper.scrap
          game.reviews.size.should eq 10
        end
      end
    end

    context 'there is a review flagged as abusive' do
      it 'should ignore it' do
        game = build :game_ar
        scrapper = build_scrapper [game]
        stub_page klass.url(game.steam_app_id), 'reviews_flagged_as_abusive'
        stub_empty klass.url(game.steam_app_id, 2)
        scrapper.scrap
        game.reviews.size.should eq 1
      end
    end


    context 'there are many pages' do
      it 'reads the reviews from each page' do
        game = build :game_ar
        scrapper = build_scrapper [game]
        stub_page klass.url(game.steam_app_id, 1), 'reviews_page_1'
        stub_page klass.url(game.steam_app_id, 2), 'reviews_page_2'
        stub_page klass.url(game.steam_app_id, 3), 'reviews_page_3'
        stub_empty klass.url(game.steam_app_id, 4)
        scrapper.scrap
        game.reviews.size.should eq 30
      end

      it 'calls the yield block for each page' do
        game = build :game_ar
        scrapper = build_scrapper [game]
        stub_page klass.url(game.steam_app_id, 1), 'reviews_page_1'
        stub_page klass.url(game.steam_app_id, 2), 'reviews_page_2'
        stub_page klass.url(game.steam_app_id, 3), 'reviews_page_3'
        stub_empty klass.url(game.steam_app_id, 4)

        expect { |b| scrapper.scrap(&b) }.to yield_control.exactly(4).times
      end
    end
  end

  describe '#subjects' do
    it 'should give the list of games that was given to it' do
      games = [build(:game_ar), build(:game_ar)]
      scrapper = build_scrapper games
      scrapper.subjects.should eq games
    end
  end
end