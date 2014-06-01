require 'spec_helper'

module PtbScrapper
  describe ExArray do
    describe '#all_numeric?' do
      it {expect(PtbScrapper::ExArray.new([1,2,3]).all_numeric?).to be_true}
      it {expect(PtbScrapper::ExArray.new([1,2,3,4,5]).all_numeric?).to be_true}
      it {expect(PtbScrapper::ExArray.new([1,'n',3,4,5]).all_numeric?).to be_false}
      it {expect(PtbScrapper::ExArray.new([1,Time.now,3,4,5]).all_numeric?).to be_false}
    end
  end
end