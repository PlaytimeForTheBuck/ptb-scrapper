require 'spec_helper'

module PtbScrapper
  module Models
    describe GameAr do
      let(:game) { build :game_ar }

      describe 'factory' do
        it 'factory creates a valid game' do
          game.should be_valid
        end
      end

      describe '#on_sale?' do
        context '#sale_price is nil' do
          it 'is false' do
            game.price = 123
            game.sale_price = nil
            game.on_sale?.should eq false
          end
        end

        context '#sale_price is not nil' do
          it 'is true' do
            game.price = 123
            game.sale_price = 100
            game.on_sale?.should eq true
          end
        end 
      end

      describe '#sale_discount' do
        context '#sale_price is nil' do
          it 'is 0' do
            game.price = 123
            game.sale_price = nil
            game.sale_discount.should eq 0
          end
        end

        context '#sale_price is not nil' do
          it 'is the percentage off' do
            game.price = 200
            game.sale_price = 100
            game.sale_discount.should eq 50
          end
        end
      end

      describe 'basic validations' do
        it 'requires a name' do
          game.name = ''
          game.should_not be_valid
        end

        it 'requires an steam app ID' do
          game.steam_app_id = nil
          game.should_not be_valid
        end

        # it 'requires a launch date' do
        #   game.launch_date = nil
        #   game.should_not be_valid
        # end

        # it 'requires price not nil' do
        #   game.price = nil
        #   game.should_not be_valid
        # end
      end

      describe '#categories' do
        it 'should be an empty array if not set' do
          game.categories.should eq []
          game.attributes[:categories].should eq nil
        end

        it 'should accept an array of categories' do
          game.categories = ['abc', 'def', 'ghi']
          game.categories.should eq ['abc', 'def', 'ghi']
        end

        it 'should be trimmed to 10 categories max' do
          game.categories = %w{a b c d e f g h i j k l m n o p q r}
          game.categories.should eq %w{a b c d e f g h i j}
        end
      end

      describe '#os' do
        it 'should be an empty array if no OS are set' do
          game.os.should eq []
        end

        it 'should be Windows if set to win' do
          game.os = [:win]
          game.os.should eq [:win]
        end

        it 'should be Mac if set to mac' do
          game.os = [:mac]
          game.os.should eq [:mac]
        end

        it 'should be Linux if set to linux' do
          game.os = [:linux]
          game.os.should eq [:linux]
        end

        it 'should accept multiple OSs' do
          game.os = [:win, :linux]
          game.os.should eq [:win, :linux]
        end

        it 'should ignore unknown OSs' do
          game.os = [:win, :linux, :potato]
          game.os.should eq [:win, :linux]
        end
      end

      describe '#os_flags' do
        it 'should be 0 if no OS are set' do
          game.os_flags.should eq 0
        end

        it 'should be 0b001 if set to windows' do
          game.os = [:win]
          game.os_flags.should eq 0b001
        end

        it 'should be 0b010 if set to mac' do
          game.os = [:mac]
          game.os_flags.should eq 0b010
        end

        it 'should be 0b100 if set to linux' do
          game.os = [:linux]
          game.os_flags.should eq 0b100
        end

        it 'should be 0b101 if set to Windows and Linux' do
          game.os = [:win, :linux]
          game.os_flags.should eq 0b101
        end

        it 'should ignore unknown OSs' do
          game.os = [:win, :linux, :potato]
          game.os_flags.should eq 0b101
        end
      end

      describe '#features' do 
        [:single_player,
        :multi_player,
        :co_op,
        :achievements,
        :cloud,
        :cards,
        :controller,
        :partial_controller,
        :stats,
        :workshop,
        :captions,
        :commentary,
        :level_editor,
        :vac,
        :vr,
        :leaderboards].each do |flag|
          it "should accept #{flag}" do
            game.features_flags.should eq 0
            game.features = [flag]
            game.features_flags.to_s(2).scan(/1/).size.should eq 1
            game.features.should eq [flag]
          end
        end

        it 'should accept multiple flags' do
          game.features_flags.should eq 0
          game.features = [:achievements, :cloud, :cards]
          game.features_flags.to_s(2).scan(/1/).size.should eq 3
          game.features.should eq [:achievements, :cloud, :cards]
        end
      end

      # describe '#available' do
      #   it 'should be true by default' do
      #     game.available.should eq true
      #   end

      #   it 'should be a regular boolean attribute' do
      #     game.available = false
      #     game.available.should eq false
      #   end
      # end

      describe 'update bang methods!' do
        describe '#update_game!' do
          it 'should update the #game_updated_at attribute' do
            last_time = Time.now      
            game.game_updated_at = last_time
            game.update_game!
            game.game_updated_at.should_not eq last_time
          end
        end

        describe '#update_game_list!' do
          it 'should update the #game_list_updated_at attribute' do
            last_time = Time.now      
            game.game_list_updated_at = last_time
            game.update_game_list!
            game.game_list_updated_at.should_not eq last_time
          end
        end

        describe '#update_reviews!' do
          it 'should update the #reviews_updated_at attribute' do
            last_time = Time.now      
            game.reviews_updated_at = last_time
            game.update_reviews!
            game.reviews_updated_at.should_not eq last_time
          end
        end
      end

      describe "#positive_reviews" do
        describe 'validations' do
          it 'is always an array' do
            game.positive_reviews = nil
            game.positive_reviews.should eq []
          end

          it 'accepts an actual array' do
            game.positive_reviews = [1,2,3]
            game.should be_valid
          end

          it 'does not accepts an string in the array' do
            game.positive_reviews = [1,'h', 3, 4]
            game.should_not be_valid
          end

          it 'does accept a float in the array' do
            game.positive_reviews = [1,1.2, 3, 4]
            game.should be_valid
          end

          it 'does not accepts time in the array' do
            game.positive_reviews = [1,Time.now, 3, 4]
            game.should_not be_valid
          end
        end

        describe 'computated methods' do
          context 'array is valid' do 
            it "#average_time_positive returns the average time for the positive" do
              game.positive_reviews = [1,3,4,7]
              game.average_time_positive.should eq (1+3+4+7)/4.0
            end

            context 'array is empty' do
              it "#average_time_positive should be 0" do
                game.positive_reviews = []
                game.average_time_positive.should eq 0
              end
            end

            it '#average_time returns the average time' do
              game.positive_reviews = [1,3,4,7]
              game.average_time.should eq (1+3+4+7)/4.0
            end

            it '#max_time returns the maximum time' do
              game.positive_reviews = [1,5,1,2,12,3]
              game.max_time.should eq 12
            end

            it '#min_time returns the minimum time' do
              game.positive_reviews = [1,5,1,2,12,3]
              game.min_time.should eq 1
            end
          end
        end
      end 

      describe "#negative_reviews" do
        describe 'validations' do
          it 'is always an array' do
            game.negative_reviews = nil
            game.negative_reviews.should eq []
          end

          it 'accepts an actual array' do
            game.negative_reviews = [1,2,3]
            game.should be_valid
          end

          it 'does not accepts an string in the array' do
            game.negative_reviews = [1,'h', 3, 4]
            game.should_not be_valid
          end

          it 'does accept a float in the array' do
            game.negative_reviews = [1,1.2, 3, 4]
            game.should be_valid
          end

          it 'does not accepts time in the array' do
            game.negative_reviews = [1,Time.now, 3, 4]
            game.should_not be_valid
          end
        end

        describe 'computated methods' do
          context 'array is valid' do 
            it "#average_time_negative returns the average time for the negative" do
              game.negative_reviews = [1,3,4,7]
              game.average_time_negative.should eq (1+3+4+7)/4.0
            end

            context 'array is empty' do
              it "#average_time_negative should be 0" do
                game.negative_reviews = []
                game.average_time_negative.should eq 0
              end
            end

            it '#average_time returns the average time' do
              game.negative_reviews = [1,3,4,7]
              game.average_time.should eq (1+3+4+7)/4.0
            end

            it '#max_time returns the maximum time' do
              game.negative_reviews = [1,5,1,2,12,3]
              game.max_time.should eq 12
            end

            it '#min_time returns the minimum time' do
              game.negative_reviews = [1,5,1,2,12,3]
              game.min_time.should eq 1
            end
          end
        end
      end

      describe "combination of #positive_reviews and #negative_reviews" do
        describe 'computated methods' do
          context 'array is valid' do
            it '#average_time returns average' do
              game.positive_reviews = [1,3]
              game.negative_reviews = [4,7]
              game.average_time.should eq (1+3+4+7)/4.0
            end

            it '#max_time returns max time' do
              game.positive_reviews = [1,5,1,2,3]
              game.negative_reviews = [2,12,10]
              game.max_time.should eq 12
            end

            it '#min_time returns min time' do
              game.positive_reviews = [10,5,5,2]
              game.negative_reviews = [2,12,3,1,3]
              game.min_time.should eq 1
            end

            describe '#playtime_deviation returns the chance you have of being 20% between the average playtime' do
              describe 'No reviews fall into the category' do
                it 'returns 0' do
                  game.positive_reviews = [6, 6, 6]
                  game.negative_reviews = [1, 1, 1]
                  # Average is 3.5
                  # -20% average is 2.8
                  # +20% average is 4.2
                  # No reviews fall inside that, therefore, it should be 0
                  game.playtime_deviation.should eq 0
                end
              end

              describe 'Some reviews fall into the category' do
                it 'returns 1 out of 7 reviews' do
                  game.positive_reviews = [6, 6, 6, 4]
                  game.negative_reviews = [1, 1, 1]
                  # Average is 3.57143
                  # -20% average is 2.85714
                  # +20% average is 4.28571
                  # One review fall that, therefore, it should be 1/7 = 14.28%
                  game.playtime_deviation.should eq 1/7.0
                end

                it 'returns 2 out of 8 reviews' do
                  game.positive_reviews = [6, 6, 6, 4]
                  game.negative_reviews = [1, 1, 1, 3]
                  # Average is 3.5
                  # -20% average is 2.8
                  # +20% average is 4.2
                  # One review fall that, therefore, it should be 2/8 = 25%
                  game.playtime_deviation.should eq 2/8.0
                end
              end

              describe 'All reviews fall into the category' do
                it 'returns 100% when the reviews are all the same' do
                  game.positive_reviews = [3,3,3,3]
                  game.negative_reviews = [3,3,3,3]
                  game.playtime_deviation.should eq 1
                end

                it 'returns 100% when the reviews are all different but within the 20% anyway' do
                  game.positive_reviews = [51,52,53,54,55]
                  game.positive_reviews = [56,57,58,59,60]
                  game.playtime_deviation.should eq  1
                end
              end

            end
          end
        end
      end

      describe '#save' do
        it 'should save the game without errors' do
          game.save!
        end

        it 'should load the game without errors' do
          game.save!
          GameAr.all.should eq [game]
        end

        it 'should save the game twice without errors' do
          game.save!
          game.save!
          GameAr.all.should eq [game]
        end

        it 'should add the previous price to #price_history' do
          game.price = 19.99
          previous_price_date = game.update_game_list!
          game.save!
          game.price = 4.99
          game.save!

          game.price_history.size.should eq 1

          previous_price = game.price_history.first
          previous_price.price.should eq 19.99
          previous_price.sale_price.should eq game.sale_price
          previous_price.date.to_i.should eq previous_price_date.to_i
        end

        it 'should add the previous sale_price to #price_history' do
          previous_price_date = game.update_game_list!
          game.sale_price = nil
          game.save!
          game.sale_price = 4.99
          game.save!

          game.price_history.size.should eq 1

          previous_price = game.price_history.first
          previous_price.price.should eq game.price
          previous_price.sale_price.should eq nil
          previous_price.date.to_i.should eq previous_price_date.to_i
        end
      end

      describe '.get_for_reviews_updating' do
        it 'should return nothing when there are no games' do
          GameAr.get_for_reviews_updating.should eq []
        end

        context 'never scrapped game' do
          it 'should return the game even if its ancient' do
            game.launch_date = Time.now - 3600*24*365*100 # 100 years ago
            game.reviews_updated_at = nil
            game.save!
            GameAr.get_for_reviews_updating.should eq [game]
          end
        end

        context 'launch date < week' do
          before :each do
            game.launch_date = Time.now - 3600*24*3 # 3 days ago
          end

          context 'no reviews' do
            context 'last update < 24 hours ago' do
              it 'should not return the game' do
                game.reviews_updated_at = Time.now - 3600*23 # 23 hours ago
                game.save!
                GameAr.get_for_reviews_updating.should eq []
              end
            end

            context 'last update > 24 hours ago' do
              it 'should return the game' do
                game.reviews_updated_at = Time.now - 3600*24 # 24 hours ago
                game.save!
                GameAr.get_for_reviews_updating.should eq [game]
              end
            end
          end
        end

        context 'week < launch date < month' do 
          before :each do
            game.launch_date = Time.now - 3600*24*15 # 15 days ago
          end

          context 'no reviews' do
            context 'last update < 7 days ago' do
              it 'should not return the game' do
                game.reviews_updated_at = Time.now - 3600*24*6 # 6 days ago
                game.save!
                GameAr.get_for_reviews_updating.should eq []
              end
            end

            context 'last update > 7 days ago' do
              it 'should return the game' do
                game.reviews_updated_at = Time.now - 3600*24*8 # 8 days ago
                game.save!
                GameAr.get_for_reviews_updating.should eq [game]
              end
            end
          end
        end

        context 'month < launch date < year' do 
          before :each do
            game.launch_date = Time.now - 3600*24*300 # 300 days ago
          end

          context 'no reviews' do
            context 'last update < 1 month ago' do
              it 'should not return the game' do
                game.reviews_updated_at = Time.now - 3600*24*27 # 27 days ago
                game.save!
                GameAr.get_for_reviews_updating.should eq []
              end
            end

            context 'last update > 1 month ago' do
              it 'should return the game' do
                game.reviews_updated_at = Time.now - 3600*24*31 # 31 days ago
                game.save!
                GameAr.get_for_reviews_updating.should eq [game]
              end
            end
          end
        end

        context '1 year < launch date < 3 years' do 
          before :each do
            game.launch_date = Time.now - 3600*24*365*2 # 2 years ago
          end

          context 'no reviews' do
            context 'last update < 3 month ago' do
              it 'should not return the game' do
                game.reviews_updated_at = Time.now - 3600*24*80 # 80 days ago
                game.save!
                GameAr.get_for_reviews_updating.should eq []
              end
            end

            context 'last update > 3 month ago' do
              it 'should return the game' do
                game.reviews_updated_at = Time.now - 3600*24*91 # 91 days ago
                game.save!
                GameAr.get_for_reviews_updating.should eq [game]
              end
            end
          end
        end

        context '3 years < launch date' do 
          before :each do
            game.launch_date = Time.now - 3600*24*365*10 # 10 years ago
          end

          context 'no reviews' do
            context 'last update < 1 year ago' do
              it 'should not return the game' do
                game.reviews_updated_at = Time.now - 3600*24*360 # 360 days ago
                game.save!
                GameAr.get_for_reviews_updating.should eq []
              end
            end

            context 'last update > 1 year ago' do
              it 'should return the game' do
                game.reviews_updated_at = Time.now - 3600*24*366 # 366 days ago
                game.save!
                GameAr.get_for_reviews_updating.should eq [game]
              end
            end
          end
        end
      end


      describe '.expire_games' do
        it 'should set all the #game_updated_at to nil' do
          game1 = build :game_ar
          game2 = build :game_ar
          game1.game_updated_at = Time.now
          game2.game_updated_at = Time.now
          game1.save!
          game2.save!
          GameAr.expire_games
          GameAr.all.first.game_updated_at.should eq nil
          GameAr.all.last.game_updated_at.should eq nil
        end
      end

      describe '#to_json' do
        it 'should return a json object of the game summary attributes' do
          attrs_string = game.to_json
          attrs_string.should eq JSON.generate(game.summary_attrs)
        end
      end

      describe '#==' do
        it 'should equal if the appid is the same' do
          game1 = build :game_ar, steam_app_id: 123
          game2 = build :game_ar, steam_app_id: 123
          game1.should eq game2
        end

        it 'should work with arrays' do
          game1 = build :game_ar, steam_app_id: 123
          game2 = build :game_ar, steam_app_id: 123
          game3 = build :game_ar, steam_app_id: 123
          game4 = build :game_ar, steam_app_id: 123
          [game1, game2].should eq [game3, game4]
        end
      end

      describe '#summary_attrs' do
        it 'should return without reviews array' do
          game.positive_reviews = [1,2,3]
          game.negative_reviews = [4,5,6]
          game.summary_attrs.should_not have_key :negative_reviews
          game.summary_attrs.should_not have_key :positive_reviews
        end

        it 'should return with reviews length' do
          game.positive_reviews = [1,2,3,4]
          game.negative_reviews = [4,5,6]
          game.summary_attrs[:positive_reviews_length].should eq 4
          game.summary_attrs[:negative_reviews_length].should eq 3
        end

        it 'should return with max and min time' do
          game.summary_attrs.should have_key :max_time
          game.summary_attrs.should have_key :min_time
        end

        it 'should return with average_time_positive' do
          game.summary_attrs.should have_key :average_time_positive
        end

        it 'should return with average_time_negative' do
          game.summary_attrs.should have_key :average_time_negative
        end

        it 'should return with average_time' do
          game.summary_attrs.should have_key :average_time
        end
        
        it 'should return with playtime_deviation' do
          game.summary_attrs.should have_key :playtime_deviation
        end

        it 'should return with categories' do
          game.summary_attrs.should have_key :categories
        end

        it 'should return with steam_app_id instead of id' do
          game.summary_attrs.should have_key :steam_app_id
          game.summary_attrs.should_not have_key :id
        end

        it 'should return #game_updated_at as integer' do
          game.game_updated_at = Time.now
          game.summary_attrs[:game_updated_at].should eq game.game_updated_at.to_i*1000
        end

        it 'should return #reviews_updated_at as integer' do
          game.reviews_updated_at = Time.now
          game.summary_attrs[:reviews_updated_at].should eq game.reviews_updated_at.to_i*1000
        end

        it 'should return #game_list_updated_at as integer' do
          game.game_list_updated_at = Time.now
          game.summary_attrs[:game_list_updated_at].should eq game.game_list_updated_at.to_i*1000
        end

        it 'should return #launch_date as integer' do
          game.launch_date = Time.now
          game.summary_attrs[:launch_date].should eq game.launch_date.to_i*1000
        end

        it 'should return #os as #os_flags' do
          game.os = [:win, :mac]
          game.summary_attrs[:os].should eq game.os_flags
        end

        it 'should not return an #os_flags attribute' do
          game.os = [:win, :mac]
          game.summary_attrs.should_not have_key :os_flags
        end

        it 'should return #features as #features_flags' do
          game.features = [:vr, :multi_player]
          game.summary_attrs[:features].should eq game.features_flags
        end

        it 'should not return an #features_flags attribute' do
          game.features = [:vr, :multi_player]
          game.summary_attrs.should_not have_key :features_flags
        end
      end
    end
  end
end