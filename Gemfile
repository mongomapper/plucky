source :rubygems
gemspec

gem 'bson_ext', '~> 1.5'
gem 'rake'

group :performance do
  gem 'perftools.rb', :require => 'perftools'
end

group(:debug) do
  platforms(:mri_18) { gem 'ruby-debug' }
  platforms(:mri_19) { gem 'ruby-debug19' }
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
