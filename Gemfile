source 'https://rubygems.org'
gemspec

gem 'bson_ext', '~> 1.5'
gem 'rake'

group :performance do
  gem 'perftools.rb', :require => 'perftools'
end

group(:test) do
  gem 'rspec'
  gem 'log_buddy'
end

group(:guard) do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'terminal-notifier-guard'
  gem 'rb-fsevent'
end
