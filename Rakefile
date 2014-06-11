require 'active_record_migrations'
require 'ptb_scrapper'

PtbScrapper.load_rake_tasks
ActiveRecordMigrations.load_tasks

desc 'Fire up Guard tests'
task :test do
  exec 'guard --force_polling -g rspec'
end

desc 'Fire up Guard tests with Rspec focus option'
task :focus do
  exec 'guard --force_polling -g focus_rspec'
end

desc 'Console with the environment loaded'
task :c do
  require 'irb'
  ARGV.clear
  IRB.start
end

task default: :test