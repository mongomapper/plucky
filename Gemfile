source :rubygems
gemspec

gem 'bson_ext'
gem 'rake'

platforms(:mri_18) { gem 'ruby-debug' }
platforms(:mri_19) { gem 'ruby-debug19' }

group(:test) do
  gem 'shoulda',            '~> 2.11'
  gem 'jnunemaker-matchy',  '~> 0.4.0'
  gem 'mocha',              '~> 0.9.8'
  gem 'log_buddy'
end
