source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails',   '3.2.6'
gem 'pg'
gem 'sqlite3'
gem 'yettings'
gem 'thin'

gem 'private_pub'

# Assets
gem 'bourbon'
gem 'paperclip', '~> 3.0'
gem 'aws-sdk'
gem 'jquery-rails'

# Caching
gem 'dalli'

# Users
gem 'devise'
gem 'cancan'
gem 'aws-ses', '~> 0.4.4', require: 'aws/ses'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'koala'

# Admin
gem 'rails_admin'

# Comments
gem 'acts_as_commentable_with_threading'
gem 'acts_as_votable'

# Crawling and parsing
gem 'nokogiri'
gem 'chronic'
gem 'anemone'
gem 'mongo_mapper'
gem 'feedzirra', github: 'NateW/feedzirra'

# APIs
gem 'soundcloud', github: 'andrejj/soundcloud-ruby'
#gem 'ruby-echonest', :git => 'git://github.com/NateW/ruby-echonest.git'

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

# Pagination
gem 'kaminari'

# Search
gem 'texticle', github: 'NateW/texticle', require: 'texticle/rails'

# Songs
gem 'discogs-wrapper'
gem 'taglib-ruby'

# Waveforms
gem 'oily_png'
gem 'waveform'
gem 'ffmpeg'

# Deploy
gem 'capistrano'
gem 'whenever', require: false

group :assets do
  gem 'sass-rails'
  gem 'uglifier'
end

group :production do
  gem 'newrelic_rpm'
end

group :development do
  gem 'foreman'
  gem 'taps'
  gem 'quiet_assets'
  gem 'awesome_print'
  gem 'capistrano_colors'
  gem 'mails_viewer'

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
