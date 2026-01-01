source 'https://rubygems.org'
gemspec

gem 'rake'

if RUBY_VERSION >= '3.4'
  # the activesupport gem depends on the bigdecimal gem, which has been extracted as a bundled gem since Ruby 3.4.
  gem 'bigdecimal'
end

if RUBY_VERSION >= '4.0'
  # the mongo gem depends on the logger gem, which has been extracted as a bundled gem since Ruby 4.0.
  gem 'logger'
end

group(:test) do
  gem 'rspec'
  gem 'log_buddy'

  if RUBY_ENGINE == "ruby" && RUBY_VERSION >= '2.3'
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
