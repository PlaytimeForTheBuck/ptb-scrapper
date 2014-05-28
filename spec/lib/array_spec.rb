require 'spec_helper'

describe Array do
  describe '#all_numeric?' do
    it {expect([1,2,3].all_numeric?).to be_true}
    it {expect([1,2,3,4,5].all_numeric?).to be_true}
    it {expect([1,'n',3,4,5].all_numeric?).to be_false}
    it {expect([1,Time.now,3,4,5].all_numeric?).to be_false}
  end
end