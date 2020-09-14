source 'https://rubygems.org'
gemspec

gem 'rake'

group(:test) do
  gem 'rspec'
  gem 'log_buddy'

  if RUBY_VERSION >= '2.3'
    platforms :mri do
      gem 'byebug'
    end
  end
end

group(:guard) do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'rb-fsevent'
end
