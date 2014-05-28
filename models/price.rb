class Price < ActiveRecord::Base
  belongs_to :game_ar, foreign_key: 'game_id'
end