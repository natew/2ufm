source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '~> 4.0'
gem 'protected_attributes', '~> 1'
gem 'yettings', '~> 0.1'
gem 'puma', '~> 2'
gem 'capistrano-puma', require: false

platform :ruby do
  gem 'pg'
  gem 'thin' # for danthes
  gem 'danthes', github: 'simonoff/danthes'
  gem 'feedzirra'
  gem 'taglib-ruby'
  # gem 'bson_ext'

  # Waveforms
  gem 'oily_png'
  gem 'waveform'
  gem 'ffmpeg'
end

platform :rbx do
  gem 'rubysl'
  gem 'racc'
  gem 'yajl-ruby'
end

platform :jruby do
  gem 'bson'
  # gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3.0.DEV', github: 'jruby/activerecord-jdbc-adapter'
  gem 'ruby-mp3info'
  gem 'torquebox-server', '3.0.0.beta2'

  group :development do
    gem 'torquebox-capistrano-support'
  end
end

# Assets
gem 'bourbon', '~> 3'
gem 'cocaine', ref: '4cae4ecc9eb03ebe65c2073bafdff38502195da4', github: 'thoughtbot/cocaine'
gem 'paperclip', '~> 3.5', github: 'thoughtbot/paperclip'
gem 'aws-sdk', '~> 1'
gem 'jquery-rails', '~> 3.0'

# Caching
# gem 'memcached'
gem 'dalli', '~> 2'
# gem 'dalli-store-extensions', github: 'johnschult/dalli-store-extensions'

# Users
gem 'devise', '~> 3'
gem 'cancan', '~> 1'
gem 'aws-ses', '~> 0.4', require: 'aws/ses'
gem 'omniauth-facebook', '~> 1.4.0'
gem 'koala', '~> 1'

# Admin
gem 'rails_admin'

# Comments
# gem 'acts_as_commentable_with_threading'
# gem 'acts_as_votable'

# Crawling and parsing
gem 'nokogiri', '1.5.9'
gem 'chronic'
gem 'anemone'
gem 'mongo_mapper'

# APIs
gem 'soundcloud', github: 'andrejj/soundcloud-ruby'
gem 'httparty'
# gem 'youtube_it'
#gem 'ruby-echonest', :git => 'git://github.com/natew/ruby-echonest.git'

# Jobs
gem 'daemons'
gem 'delayed_job_active_record'

# General
gem 'stringex', github: 'rsl/stringex'
# gem 'curb'
gem 'sanitize'
gem 'hashie'
gem 'recaptcha'

# Pagination
gem 'kaminari'

# Search
# gem 'texticle', github: 'natew/texticle'

# Songs
gem 'discogs-wrapper', github: 'natew/discogs'

# Deploy
gem 'whenever', require: false

group :assets do
  gem 'sass-rails', '4.0.0'
  gem 'uglifier'
end

group :production do
end

group :development do
  gem 'capistrano', require: false
  gem 'foreman'
  gem 'taps'
  gem 'quiet_assets'
  gem 'awesome_print'
  gem 'capistrano_colors'
  gem 'mails_viewer'
  # gem 'better_errors'
  # gem 'binding_of_caller'

  # gem 'marginalia' # Adds nice info to SQL statements, supposedly (not working yet)
  # gem 'bullet'
  # gem 'active_record_query_trace'
  # gem 'sql-logging', :git => 'git://github.com/pnc/sql-logging.git', :branch => 'rails-3-2-fix'
  # gem 'ruby-debug19', :require => 'ruby-debug'
end

group :test do
  # Pretty printed test output
  gem 'turn', require: false
  gem 'database_cleaner'
end
