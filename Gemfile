source :rubygems
gemspec

gem 'bson_ext', '~> 1.5'
gem 'rake'

group(:debug) do
  platforms(:mri_18) { gem 'ruby-debug' }
  platforms(:mri_19) { gem 'ruby-debug19' }
end

group(:test) do
  gem 'shoulda',            '~> 2.11'
  gem 'jnunemaker-matchy',  '~> 0.4.0', :require => 'matchy'
  gem 'mocha',              '~> 0.9.8'
  gem 'log_buddy'
end
