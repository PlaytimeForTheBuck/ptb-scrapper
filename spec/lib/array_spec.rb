require 'spec_helper'

describe Array do
  describe '#all_numeric?' do
    it {expect([1,2,3].all_numeric?).to be_true}
    it {expect([1,2,3,4,5].all_numeric?).to be_true}
    it {expect([1,'n',3,4,5].all_numeric?).to be_false}
    it {expect([1,Time.now,3,4,5].all_numeric?).to be_false}
  end

  describe '#centile' do
    describe 'centile 1' do
      it {expect([1,2,3,4,5].centile(1)).to eq 1}
      it {expect([0.5,1.5,2.5,3.5,4.5].centile(1)).to eq 1}
      it {expect([1,1,2,2,3,3,4,4,5,5].centile(1)).to eq 2}
      it {expect([1,1,1,1,1].centile(1)).to eq 0}
      it {expect([1,1,2,1,1].centile(1)).to eq 4}
      it {expect([1,1,1,2,3,4,5].centile(1)).to eq 3}
      it {expect([3,3,4,4,5,6,7].centile(1)).to eq 2}
      it {expect([1,2,3,25,100,35,50,55,50].centile(1)).to eq 3}
    end

    describe 'centile 2' do
      it {expect([1,2,3,4,5].centile(2)).to eq 1}
      it {expect([1,1,2,2,3,3,4,4,5,5].centile(2)).to eq 2}
      it {expect([1,1,1,1,1].centile(2)).to eq 0}
      it {expect([1,1,2,1,1].centile(2)).to eq 0}
      it {expect([1,1,1,2,3,4,5].centile(2)).to eq 1}
      it {expect([3,3,4,4,5,6,7].centile(2)).to eq 2}
      it {expect([1,2,3,25,100,35,50,55,50].centile(2)).to eq 2}
    end

    describe 'centile 3' do
      it {expect([1,2,3,4,5].centile(3)).to eq 1}
      it {expect([1,1,2,2,3,3,4,4,5,5].centile(3)).to eq 2}
      it {expect([1,1,1,1,1].centile(3)).to eq 5}
      it {expect([1,1,2,1,1].centile(3)).to eq 0}
      it {expect([1,1,1,2,3,4,5].centile(3)).to eq 1}
      it {expect([3,3,4,4,5,6,7].centile(3)).to eq 1}
      it {expect([1,2,3,25,100,35,50,55,50].centile(3)).to eq 3}
    end

    describe 'centile 4' do
      it {expect([1,2,3,4,5].centile(4)).to eq 1}
      it {expect([1,1,2,2,3,3,4,4,5,5].centile(4)).to eq 2}
      it {expect([1,1,1,1,1].centile(4)).to eq 0}
      it {expect([1,1,2,1,1].centile(4)).to eq 0}
      it {expect([1,1,1,2,3,4,5].centile(4)).to eq 1}
      it {expect([3,3,4,4,5,6,7].centile(4)).to eq 1}
      it {expect([1,2,3,25,100,35,50,55,50].centile(4)).to eq 0}
    end

    describe 'centile 5' do
      it {expect([1,2,3,4,5].centile(5)).to eq 1}
      it {expect([1,1,2,2,3,3,4,4,5,5].centile(5)).to eq 2}
      it {expect([1,1,1,1,1].centile(5)).to eq 0}
      it {expect([1,1,2,1,1].centile(5)).to eq 1}
      it {expect([1,1,1,2,3,4,5].centile(5)).to eq 1}
      it {expect([3,3,4,4,5,6,7,7,7,7].centile(5)).to eq 4}
      it {expect([1,2,3,25,100,35,50,55,50].centile(5)).to eq 1}
    end
  end
end