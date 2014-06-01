# A sample Guardfile
# More info at https://github.com/guard/guard#readme

group :rspec do
  guard :rspec, cmd: 'bundle exec rspec -b', all_on_start: true do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^spec/factories/.+_factory\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch(%r{^models/(.+)\.rb$})     { |m| "spec/models/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb') { 'spec' }
    watch(%r{^ptb_scrapper/.+\.rb$})
    watch(%r{^ptb_scrapper/ptb_scrapper/.+\.rb$})
    watch(%r{^ptb_scrapper/ptb_scrapper/scrappers/.+\.rb$})
    watch(%r{^ptb_scrapper/ptb_scrapper/models/.+\.rb$})
  end
end

group :focus_rspec do 
  guard :rspec, cmd: 'bundle exec rspec -b --tag focus', all_on_start: true do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^spec/factories/.+_factory\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch(%r{^models/(.+)\.rb$})     { |m| "spec/models/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb') { 'spec' }
    watch(%r{^ptb_scrapper/.+\.rb$})
    watch(%r{^ptb_scrapper/ptb_scrapper/.+\.rb$})
    watch(%r{^ptb_scrapper/ptb_scrapper/scrappers/.+\.rb$})
    watch(%r{^ptb_scrapper/ptb_scrapper/models/.+\.rb$})
  end
end