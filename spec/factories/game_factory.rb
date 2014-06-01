FactoryGirl.define do
  factory :game_ar, class: PtbScrapper::Models::GameAr do
    name 'Team Fortress 2'
    steam_app_id 440
    launch_date Time.parse '10 Oct 2007'
    price 10
  end
end