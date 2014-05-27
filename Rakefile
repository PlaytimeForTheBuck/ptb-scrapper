require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks

desc 'Test'
task :test do
  exec 'guard --force_polling'
end

task default: :test