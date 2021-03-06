ENV['APP_ENV'] = 'test'

require 'ptb_scrapper' 

require 'webmock/rspec'
require 'factory_girl'
require 'shoulda'
require 'fakefs/safe'
require 'fakefs/spec_helpers'
require 'database_cleaner'

PtbScrapper.init
 
RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  # config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #config.order = "random"

  # Factory girl
  config.before(:suite) { FactoryGirl.reload }
  config.include FactoryGirl::Syntax::Methods

  Mail.defaults do
    delivery_method :test
  end

  DatabaseCleaner.strategy = :truncation
  config.around do |example|
    # DatabaseCleaner.clean_with :truncation
    # example.run
    PtbScrapper.reset
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
