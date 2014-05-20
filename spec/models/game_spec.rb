require 'spec_helper'

describe Game do
  let(:game) { build :game }
  before(:each) { Game.cleanup }

  def log
    @log ||= Yell.new STDOUT
  end
     
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

    # it 'requires a price' do
    #   game.price = nil
    #   game.should_not be_valid
    # end

    it 'works with a 0 price' do
      game.price = 0
      game.should be_valid
    end
  end

  describe '#categories' do
    it 'should be nil if not set' do
      game.categories.should eq nil
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

  describe '#update_categories!' do
    it 'should update the #categories_updated_at attribute' do
      last_time = Time.now      
      game.categories_updated_at = last_time
      game.update_categories!
      game.categories_updated_at.should_not eq last_time
    end
  end

  %W{positive negative}.each do |posneg|
    describe "#array_#{posneg}_reviews" do
      before :each do
        # We do this so we dont have to repeat the tests twice
        Game.send :alias_attribute, :array_posneg_reviews, :"array_#{posneg}_reviews"
        Game.send :alias_attribute, :average_time_posneg, :"average_time_#{posneg}"
        Game.send :alias_attribute, :posneg_reviews, :"#{posneg}_reviews"
      end

      describe 'validations' do
        it 'is always an array' do
          game.array_posneg_reviews = nil
          game.array_posneg_reviews.should eq []
        end

        it 'accepts an actual array' do
          game.array_posneg_reviews = [1,2,3]
          game.should be_valid
        end

        it 'does not accepts an string in the array' do
          game.array_posneg_reviews = [1,'h', 3, 4]
          game.should_not be_valid
        end

        it 'does accept a float in the array' do
          game.array_posneg_reviews = [1,1.2, 3, 4]
          game.should be_valid
        end

        it 'does not accepts time in the array' do
          game.array_posneg_reviews = [1,Time.now, 3, 4]
          game.should_not be_valid
        end
      end

      describe '#save!' do
        context 'array is valid' do
          it "sets a #average_time_#{posneg} after save" do
            game.array_posneg_reviews = [1,2,3]
            game.save!
            game.average_time_posneg.should eq (1+2+3)/3.0
          end

          it "sets a different #average_time_#{posneg} after save" do
            game.array_posneg_reviews = [1,3,4,7]
            game.save!
            game.average_time_posneg.should eq (1+3+4+7)/4.0
          end

          context 'array is empty' do
            it "sets #average_time_#{posneg} to 0" do
              game.array_posneg_reviews = []
              game.save!
              game.average_time_posneg.should eq 0
            end
          end

          it 'sets a #average_time after save' do
            game.array_posneg_reviews = [1,2,3]
            game.save!
            game.average_time.should eq (1+2+3)/3.0
          end

          it 'sets a different #average_time after save' do
            game.array_posneg_reviews = [1,3,4,7]
            game.save!
            game.average_time.should eq (1+3+4+7)/4.0
          end

          it 'sets #max_time after save' do
            game.array_posneg_reviews = [1,5,1,2,12,3]
            game.save!
            game.max_time.should eq 12
          end

          it 'sets #min_time after save' do
            game.array_posneg_reviews = [1,5,1,2,12,3]
            game.save!
            game.min_time.should eq 1
          end

          it 'sets #reviews_centile_1' do
            game.array_posneg_reviews = [0.5,0.8,1.1,1,1,1,2,3,3,4,5]

            game.save!
            game.reviews_centile_1.should eq 6
          end

          it 'sets #reviews_centile_2' do
            game.array_posneg_reviews = [1,1.5,2,2.3,3,3,4,5]
            game.save!
            game.reviews_centile_2.should eq 2
          end

          it 'sets #reviews_centile_3' do
            game.array_posneg_reviews = [1,2,2.7,3,3,3.1,4,5]
            game.save!
            game.reviews_centile_3.should eq 4
          end

          it 'sets #reviews_centile_4' do
            game.array_posneg_reviews = [1,2,3,4,4,4,4.3,5,6,7,8,9,10]
            game.save!
            game.reviews_centile_4.should eq 2
          end

          it 'sets #reviews_centile_5' do
            game.array_posneg_reviews = [1,2,3,4,5,6,7,950,1000]
            game.save!
            game.reviews_centile_5.should eq 2
          end

          it "sets ##{posneg}_reviews" do
            game.array_posneg_reviews = [1,2,3,4,5,6,10]
            game.save!
            game.posneg_reviews.should eq 7
          end
        end
      end
    end
  end

  describe "combination of #array_positive_reviews and #array_negative_reviews" do
    describe '#save!' do
      context 'array is valid' do
        it 'sets a #average_time after save' do
          game.array_positive_reviews = [1,2]
          game.array_negative_reviews = [3]
          game.save!
          game.average_time.should eq (1+2+3)/3.0
        end

        it 'sets a different #average_time after save' do
          game.array_positive_reviews = [1,3]
          game.array_negative_reviews = [4,7]
          game.save!
          game.average_time.should eq (1+3+4+7)/4.0
        end

        it 'sets #max_time after save' do
          game.array_positive_reviews = [1,5,1,2,3]
          game.array_negative_reviews = [2,12,10]
          game.save!
          game.max_time.should eq 12
        end

        it 'sets #min_time after save' do
          game.array_positive_reviews = [10,5,5,2]
          game.array_negative_reviews = [2,12,3,1,3]
          game.save!
          game.min_time.should eq 1
        end

        it 'sets #reviews_centile_1' do
          game.array_positive_reviews = [1,1,2,3,3,4,5]
          game.array_negative_reviews = [0.5,0.8,1.1,1]

          game.save!
          game.reviews_centile_1.should eq 6
        end

        it 'sets #reviews_centile_2' do
          game.array_positive_reviews = [1,1.5,2]
          game.array_negative_reviews = [2.3,3,3,4,5]
          game.save!
          game.reviews_centile_2.should eq 2
        end

        it 'sets #reviews_centile_3' do
          game.array_positive_reviews = [3,3,3.1,4,5]
          game.array_negative_reviews = [1,2,2.7]
          game.save!
          game.reviews_centile_3.should eq 4
        end

        it 'sets #reviews_centile_4' do
          game.array_positive_reviews = [5,6,7,8,9,10]
          game.array_negative_reviews = [1,2,3,4,4,4,4.3]
          game.save!
          game.reviews_centile_4.should eq 2
        end

        it 'sets #reviews_centile_5' do
          game.array_positive_reviews = [1000]
          game.array_negative_reviews = [1,2,3,4,5,6,7,950]
          game.save!
          game.reviews_centile_5.should eq 2
        end

        it 'updates the #reviews_updated_at' do
          game.array_positive_reviews = [1,2]
          game.array_negative_reviews = [3,4]
          last_time = Time.now
          game.reviews_updated_at = last_time
          game.save!
          game.reviews_updated_at.should eq last_time
        end

        it "sets the playtime deviation" do
          game.array_positive_reviews = [100,100,100]
          game.array_negative_reviews = [1,1,1]
          game.save!
          game.playtime_deviation.should eq Math.sqrt((100*100+100*100+100*100+1*1+1*1+1*1)/6)
        end
      end
    end
  end

  describe '#update_reviews!' do
    it 'should update the time of the reviews' do
      last_time = Time.now      
      game.reviews_updated_at = last_time
      game.update_reviews!
      game.reviews_updated_at.should_not eq last_time
    end
  end

  describe '#update_game!' do 
    it 'should update the time of the game' do
      last_time = Time.now      
      game.game_updated_at = last_time
      game.update_game!
      game.game_updated_at.should_not eq last_time
    end
  end

  describe '.set_dataset' do
    it 'should create a game from the dataset' do
      attrs = attributes_for :game
      Game.all.should eq []
      Game.set_dataset([attrs])
      Game.all.size.should eq 1
      Game.all.first.class.should eq Game
    end
  end

  describe '.set_file' do
    it 'should create a dataset and games from the file' do
      game = build :game
      Game.all.should eq []
      Game.dataset.should eq []
      file = StringIO.new [game].to_json
      Game.set_file(file)
      Game.all.should eq [game]
      Game.dataset.should eq [game.attributes]
    end
  end

  describe '.save_to_file' do
    it 'should save the dataset to file' do
      game = build :game
      file = StringIO.new ''
      Game.set_file file
      game.save!
      Game.save_to_file
      file.string.should eq [game].to_json
    end

    context 'calling it twice' do 
      it 'should rewrite everything' do
        game = build :game
        file = StringIO.new ''
        Game.set_file file
        game.save!
        Game.save_to_file
        Game.save_to_file
        file.string.should eq [game].to_json
      end
    end
  end

  describe '.all' do
    it 'should return the game created through .new and saved' do 
      game.save!
      Game.all.should eq [game]
    end

    it 'should not save it twice' do 
      game.save!
      game.save!
      Game.all.should eq [game]
    end
  end

  describe '.dataset' do
    it 'should return the dataset stated by .set_dataset' do
      attrs = attributes_for :game
      Game.set_dataset([attrs])
      Game.dataset.should eq [attrs]
    end

    it 'should return the updated dataset after changing the game' do
      attrs = attributes_for :game
      Game.set_dataset [attrs]      
      game = Game.all.first
      game.name = 'rsarsarsa'

      Game.dataset.first[:name].should eq 'rsarsarsa'
    end

    it 'should not save it twice' do 
      game.save!
      game.save!
      Game.dataset.should eq [game.attributes]
    end
  end

  describe '.get_for_reviews_updating games' do
    it 'should return nothing when there are no games' do
      Game.get_for_reviews_updating.should eq []
    end

    context 'never scrapped game' do
      it 'should return the game even if its ancient' do
        game.launch_date = Time.now - 3600*24*365*100 # 100 years ago
        game.reviews_updated_at = nil
        game.save!
        Game.get_for_reviews_updating.should eq [game]
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
            Game.get_for_reviews_updating.should eq []
          end
        end

        context 'last update > 24 hours ago' do
          it 'should return the game' do
            game.reviews_updated_at = Time.now - 3600*24 # 24 hours ago
            game.save!
            Game.get_for_reviews_updating.should eq [game]
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
            Game.get_for_reviews_updating.should eq []
          end
        end

        context 'last update > 7 days ago' do
          it 'should return the game' do
            game.reviews_updated_at = Time.now - 3600*24*8 # 8 days ago
            game.save!
            Game.get_for_reviews_updating.should eq [game]
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
            Game.get_for_reviews_updating.should eq []
          end
        end

        context 'last update > 1 month ago' do
          it 'should return the game' do
            game.reviews_updated_at = Time.now - 3600*24*31 # 31 days ago
            game.save!
            Game.get_for_reviews_updating.should eq [game]
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
            Game.get_for_reviews_updating.should eq []
          end
        end

        context 'last update > 3 month ago' do
          it 'should return the game' do
            game.reviews_updated_at = Time.now - 3600*24*91 # 91 days ago
            game.save!
            Game.get_for_reviews_updating.should eq [game]
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
            Game.get_for_reviews_updating.should eq []
          end
        end

        context 'last update > 1 year ago' do
          it 'should return the game' do
            game.reviews_updated_at = Time.now - 3600*24*366 # 366 days ago
            game.save!
            Game.get_for_reviews_updating.should eq [game]
          end
        end
      end
    end
  end

  describe '#to_json' do
    it 'should return a json object of the game attributes' do
      attrs_string = game.to_json
      attrs_string.should eq JSON.generate(game.attributes)
    end
  end

  describe '#==' do
    it 'should equal if the appid is the same' do
      game1 = build :game, steam_app_id: 123
      game2 = build :game, steam_app_id: 123
      game1.should eq game2
    end

    it 'should work with arrays' do
      game1 = build :game, steam_app_id: 123
      game2 = build :game, steam_app_id: 123
      game3 = build :game, steam_app_id: 123
      game4 = build :game, steam_app_id: 123
      [game1, game2].should eq [game3, game4]
    end
  end

  describe '#summary_attrs' do
    it 'should return without reviews array' do
      game = build :game
      game.array_positive_reviews = [1,2,3]
      game.array_negative_reviews = [4,5,6]
      game.save!
      game.summary_attrs.should_not have_key :array_negative_reviews
      game.summary_attrs.should_not have_key :array_positive_reviews
    end

    it 'should not return centiles' do
      game = build :game
      game.array_positive_reviews = [1,2,3]
      game.array_negative_reviews = [4,5,6]
      game.save!
      game.summary_attrs.should_not have_key :reviews_centile_1
      game.summary_attrs.should_not have_key :reviews_centile_2
      game.summary_attrs.should_not have_key :reviews_centile_3
      game.summary_attrs.should_not have_key :reviews_centile_4
      game.summary_attrs.should_not have_key :reviews_centile_5
    end

    # it 'should return with playtime_deviation_percentage' do
    #   game = build :game
    #   game.array_positive_reviews = [1,2,3]
    #   game.array_negative_reviews = [4,5,6]
    #   game.save!
    #   mean = (1+2+3+4+5+6) / 6
    #   deviation = Math.sqrt((1*1+2*2+3*3+4*4+5*5+6*6)/6)
    #   deviation_percentage = (mean/deviation * 100 - 1).floor / 100
    #   game.summary_attrs[:playtime_deviation_percentage].should eq deviation_percentage
    # end
  end
end
