require 'spec_helper'
require 'fakefs/spec_helpers'

module PtbScrapper
  describe Logger, focus: true do
    include FakeFS::SpecHelpers
    it 'should log the thing to the log file' do
      Dir.glob('log_directory/test*').size.should eq 0
      PtbScrapper.config.log_directory = '/log_directory'
      PtbScrapper::Logger.logger.info 'THING!!!'
      log_data = File.read Dir.glob('log_directory/test*').first
      log_data.should match /THING!!!/
    end
  end
end