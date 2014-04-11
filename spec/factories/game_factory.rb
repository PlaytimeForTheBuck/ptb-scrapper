FactoryGirl.define do
  factory :game do
    name 'Team Fortress 2'
    steam_app_id 440
    launch_date Time.parse '10 Oct 2007'
    price 10
    array_positive_reviews { [] }
    array_negative_reviews { [] }
  end
end