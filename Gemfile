source 'https://rubygems.org'
gemspec

gem 'rake'

group :performance  do
  gem 'perftools.rb', :require => 'perftools', :platform => :mri
end

group(:test) do
  gem 'rspec'
  gem 'log_buddy'
end

group(:guard) do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'rb-fsevent'
end
