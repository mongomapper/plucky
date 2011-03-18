source :rubygems

require File.expand_path('../lib/plucky/version', __FILE__)
gem 'bson_ext', Plucky::MongoVersion

gemspec

gem 'rake'
gem 'ruby-debug', :platform => :ruby_18
gem 'ruby-debug19', :platform => :ruby_19, :require => 'ruby-debug'

group(:test) do
  gem 'shoulda',            '~> 2.11'
  gem 'jnunemaker-matchy',  '~> 0.4.0'
  gem 'mocha',              '~> 0.9.8'
  gem 'log_buddy'
end