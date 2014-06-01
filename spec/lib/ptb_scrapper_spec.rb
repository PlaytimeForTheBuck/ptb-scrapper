require 'spec_helper'

describe PtbScrapper do
  describe 'configuration' do
    it 'should allow to configure the game class' do
      custom_class = Class.new(PtbScrapper::Models::GameAr)
      PtbScrapper.setup do |config|
        config.game_class = custom_class
      end
      PtbScrapper.config.game_class.should eq custom_class
    end

    it 'should allow to configure the log directory' do
      PtbScrapper.setup do |config|
        config.log_directory = 'tmp/log'
      end
      PtbScrapper.config.log_directory.should eq 'tmp/log'
    end

    it 'should allow to set the logger' do
      new_logger = Yell.new STDOUT
      PtbScrapper.setup do |config|
        config.logger = new_logger
      end
      PtbScrapper.config.logger.should eq new_logger
      PtbScrapper::Logger.logger.should eq new_logger
    end
  end

  describe '.init' do
    it 'should reset the configuration' do
      PtbScrapper.setup do |c|
        c.log_directory = 'rsarsa'
      end
      PtbScrapper.config.log_directory.should eq 'rsarsa'
      PtbScrapper.init
      PtbScrapper.config.log_directory.should_not eq 'rsarsa'
    end

    it 'should reset the Logger directory' do
      new_logger = Yell.new STDOUT
      PtbScrapper.setup do |config|
        config.logger = new_logger
      end
      PtbScrapper::Logger.logger.should eq new_logger
      PtbScrapper.init
      PtbScrapper::Logger.logger.should_not eq new_logger
    end
  end
end