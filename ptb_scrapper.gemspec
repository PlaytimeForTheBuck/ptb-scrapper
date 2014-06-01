Gem::Specification.new do |s|
  s.authors = ['Ezequiel Adrián Schwartzman']
  s.email = 'zequez@gmail.com'
  s.name = 'ptb_scrapper'
  s.version = "0.1.0"
  s.date = '2014-05-30'
  s.summary = 'Ste*m scrapper for PlayTimeForTheBuck'
  s.files = [
    "Gemfile"
  ]
  s.license = 'GPLv3'
  
  s.add_dependency 'activerecord'
  s.add_dependency 'nokogiri'
  s.add_dependency 'mail'
  s.add_dependency 'yell'
  s.add_dependency 'sqlite3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'shoulda' # For better testing
  s.add_development_dependency 'guard' # For continuous testing
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'active_record_migrations'
  s.add_development_dependency 'database_cleaner'
end