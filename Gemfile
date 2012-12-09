source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails',   '3.2.6'
gem 'pg'
gem 'yettings'
gem 'thin'

gem 'danthes', github: 'simonoff/danthes'

# Assets
gem 'bourbon'
gem 'cocaine', '= 0.3.2'
gem 'paperclip', '~> 3.0'
gem 'aws-sdk'
gem 'jquery-rails'

# Caching
gem 'dalli', '~> 2.5.0'
# gem 'dalli-store-extensions', github: 'johnschult/dalli-store-extensions'

# Users
gem 'devise'
gem 'cancan'
gem 'aws-ses', '~> 0.4.4', require: 'aws/ses'
gem 'omniauth-facebook'
gem 'koala'

# Admin
gem 'rails_admin'

# Comments
# gem 'acts_as_commentable_with_threading'
# gem 'acts_as_votable'

# Crawling and parsing
gem 'nokogiri'
gem 'chronic'
gem 'anemone'
gem 'mongo_mapper'
gem 'feedzirra', github: 'natew/feedzirra'

# APIs
gem 'soundcloud', github: 'andrejj/soundcloud-ruby'
gem 'httparty'
gem 'youtube_it'
#gem 'ruby-echonest', :git => 'git://github.com/natew/ruby-echonest.git'

# Jobs
gem 'daemons'
gem 'delayed_job_active_record'

# General
gem 'stringex', github: 'rsl/stringex'
gem 'curb'
gem 'loofah-activerecord'
gem 'sanitize'
gem 'hashie'
gem 'bson_ext'
gem 'recaptcha'

# Pagination
gem 'kaminari'

# Search
gem 'texticle', github: 'natew/texticle', require: 'texticle/rails'

# Songs
gem 'discogs-wrapper', github: 'natew/discogs'
gem 'taglib-ruby'

# Waveforms
gem 'oily_png'
gem 'waveform'
gem 'ffmpeg'

# Deploy
gem 'whenever', require: false

group :assets do
  gem 'sass-rails'
  gem 'uglifier'
end

group :production do
  gem 'newrelic_rpm'
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
