source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails', '3.2.2'
gem 'pg'
gem 'yettings'

# Assets
gem 'bourbon'
gem 'paperclip', '~> 3.0'
gem 'aws-sdk'
gem 'aws-ses'
gem 'jquery-rails'

# Users
gem 'devise'
gem 'cancan'

# Crawling and parsing
gem 'nokogiri'
gem 'chronic'
gem 'anemone'
gem 'mongo_mapper'
gem 'feedzirra', :git => 'git://github.com/NateW/feedzirra.git'

# APIs
gem 'soundcloud', :git => 'git://github.com/andrejj/soundcloud-ruby.git'

# Jobs
gem 'daemons'
gem 'delayed_job_active_record'
gem 'delayed_job_admin'

# General
gem 'stringex', :git => 'git://github.com/rsl/stringex.git'
gem 'curb'
gem 'loofah-activerecord'
gem 'sanitize'
gem 'kaminari'
gem 'hashie'
gem 'texticle', :git => 'git://github.com/texticle/texticle.git', :require => 'texticle/rails'
gem 'bson_ext'
gem 'discogs-wrapper'
gem 'taglib-ruby'

# Waveforms
gem 'oily_png'
gem 'waveform'
gem 'ffmpeg'

# Deploy
gem 'capistrano'
gem 'whenever', :require => false

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'uglifier'
end

group :development do
  gem 'foreman'
  gem 'taps'
  gem 'quiet_assets'
  gem 'thin'
  gem 'awesome_print'
  gem 'marginalia' # Adds nice info to SQL statements, supposedly (not working yet)
  gem 'capistrano_colors'
  # gem 'sql-logging', :git => 'https://pnc@github.com/pnc/sql-logging.git', :branch => 'rails-3-2-fix'
  # gem 'ruby-debug19', :require => 'ruby-debug'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end
