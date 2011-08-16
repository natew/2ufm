# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Fusefm::Application

use Fusefm::Autoscale,
  :username  => ENV["HEROKU_USERNAME"],
  :password  => ENV["HEROKU_PASSWORD"],
  :app_name  => ENV["HEROKU_APP_NAME"],
  :min_dynos => 0,
  :max_dynos => 2,
  :queue_wait_low  => 100,  # milliseconds
  :queue_wait_high => 5000, # milliseconds
  :min_frequency   => 10    # seconds