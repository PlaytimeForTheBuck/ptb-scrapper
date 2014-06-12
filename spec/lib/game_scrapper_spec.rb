require 'spec_helper'

describe PtbScrapper::Scrappers::GameScrapper do
  let(:klass) { PtbScrapper::Scrappers::GameScrapper }

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

  def stub_game_request(game, name)
    stub_page(klass.url(game.steam_app_id), name)
  end

  describe '#scrap' do
    context 'valid markup' do
      it 'updates the categories of the game' do
        game = build :game_ar
        stub_game_request(game, 'categories_valid')
        scrapper = build_scrapper [game]
        scrapper.scrap
        game.categories.should eq ['Turn-based Strategy', 'Strategy', 'One More Turn',
                                   'Turn-based', 'Addictive', 'Multiplayer',
                                   '4X', 'Timesink', 'Historic', 'Singleplayer']
      end

      describe 'operative system' do
        it 'reads the OS as windows correctly' do
          game = build :game_ar 
          stub_game_request(game, 'game_os_win')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.os.should eq [:win]
        end

        it 'reads the OS as windows & linux correctly' do
          game = build :game_ar 
          stub_game_request(game, 'game_os_win_linux')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.os.should eq [:win, :linux]
        end

        it 'reads the OS as windows & mac & linux correctly' do
          game = build :game_ar 
          stub_game_request(game, 'game_os_win_osx_linux')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.os.should eq [:win, :mac, :linux]
        end

        it "should set the OS to an empty array if it doesn't have any OS" do
          game = build :game_ar
          game.os = [:win]    
          stub_game_request(game, 'game_os_empty')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.os.should eq []
        end
      end

      describe 'features' do
        it 'reads achievements, multi-player, stats, vac, partial controller, cards and workshop' do
          game = build :game_ar 
          stub_game_request(game, 'game_features_multi_player_achievements_stats_vac_partial_controller_cards_workshop')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.features.should include :multi_player, :achievements, :stats, :vac, :partial_controller, :cards, :workshop
        end

        it 'reads commentary, captions, vr, level editor' do
          game = build :game_ar 
          stub_game_request(game, 'game_features_commentary_captions_vr_level_editor')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.features.should include :commentary, :captions, :vr, :level_editor
        end

        it 'reads leaderboard, full controller support' do
          game = build :game_ar 
          stub_game_request(game, 'game_features_leaderboards_controller')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.features.should include :leaderboards, :controller
        end

        it 'reads cloud, co-op, single-player' do
          game = build :game_ar 
          stub_game_request(game, 'game_features_cloud_coop_single_player')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.features.should include :cloud, :co_op, :single_player
        end

        it 'sets partial controller support if the game has full controller support' do
          game = build :game_ar 
          stub_game_request(game, 'game_features_leaderboards_controller')
          scrapper = build_scrapper [game]
          scrapper.scrap
          game.features.should include :leaderboards, :controller, :partial_controller
        end
      end

      it 'updates the #game_updated_at attribute' do
        time_now = Time.now
        game = build :game_ar
        game.game_updated_at = time_now
        stub_game_request(game, 'categories_valid')
        scrapper = build_scrapper [game]
        scrapper.scrap
        game.game_updated_at.should_not eq time_now
      end
    end

    context 'region locked' do
      it 'should ignore the game' do
        game = build :game_ar
        stub_game_request(game, 'categories_region_locked_error')
        scrapper = build_scrapper [game]
        scrapper.scrap
        game.categories.should eq []
      end
    end

    context 'invalid markup' do
      it 'should raise an InvalidHTML error' do
        game = build :game_ar
        stub_game_request(game, 'categories_invalid')
        scrapper = build_scrapper [game]
        -> {scrapper.scrap}.should raise_error PtbScrapper::Scrappers::InvalidHTML
      end
    end

  end
end