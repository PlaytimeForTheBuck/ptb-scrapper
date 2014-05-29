# A sample Guardfile
# More info at https://github.com/guard/guard#readme

group :rspec do
  guard :rspec, cmd: 'bundle exec rspec --env test', all_on_start: true do#, cli: '--tag focus' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^spec/factories/.+_factory\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch(%r{^models/(.+)\.rb$})     { |m| "spec/models/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb') { 'spec' }
    watch('init.rb')  { 'spec' }
  end
end

group :focus_rspec do
  guard :rspec, cmd: 'bundle exec rspec --env test', all_on_start: true, cli: '--tag focus' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^spec/factories/.+_factory\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
    watch(%r{^models/(.+)\.rb$})     { |m| "spec/models/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb') { 'spec' }
    watch('init.rb')  { 'spec' }
  end
end