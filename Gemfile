source 'http://rubygems.org'

ruby '2.3.1'

# Core bits needed to run the thing
gem 'rack',          '~> 1.4.1'
gem 'rack-cors',     '~> 0.2.8'
gem 'grape',         '~> 0.7.0'
gem 'grape-entity',  '~> 0.4.2'
gem 'json',          '~> 1.8.0'
gem 'bcrypt'
gem 'hash-path'

# task runner
gem 'rake',          '~> 10.0.3'

group :development do
  gem 'guard',         '~> 2.10.5'
  gem 'guard-bundler', '~> 2.1.0'
  gem 'guard-rack',    '~> 2.0.0'
  gem 'rubocop'
  gem 'pry'
  gem 'pry-doc'
end

group :test do
  gem 'rspec',            '~> 2.13.0'
  gem 'rack-test',        '~> 0.6.2'
  # gem 'database_cleaner', '~> 1.2.0'
  # gem 'factory_girl',     '~> 4.4.0'
  # gem 'faker',            '~> 1.3.0'
end

group :production do
  gem 'unicorn'
end
