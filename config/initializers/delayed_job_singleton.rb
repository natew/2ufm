# if Rails.env == 'production'
#   PRESUMPTIVE_RAILS_ROOT = "/var/www/2u.fm/web/current"
#   LOG_PATH = "/var/www/2u.fm/shared/log/delayed_job_singleton.log"

#   Dir.chdir PRESUMPTIVE_RAILS_ROOT

#   require 'home_run'
#   require "rubygems"
#   require "bundler/setup"
#   require 'daemon_spawn'

#   class DelayedJobSingleton < DaemonSpawn::Base
#     def start(args)
#       require "/var/www/2u.fm/web/current/config/environment.rb"
#       f = open LOG_PATH, (File::WRONLY | File::APPEND | File::CREAT)
#       f.sync = true
#       RAILS_DEFAULT_LOGGER.auto_flushing = true
#       RAILS_DEFAULT_LOGGER.instance_variable_set(:@log, f)
#       Delayed::Worker.logger = RAILS_DEFAULT_LOGGER
#       Delayed::Worker.new(:quiet => true).start
#     end

#     def stop
#     end
#   end

#   DelayedJobSingleton.spawn!(:log_file => LOG_PATH,
#                              :pid_file => "/var/www/2u.fm/web/shared/pids/delayed_job_singleton.pid",
#                              :sync_log => true,
#                              :working_dir => PRESUMPTIVE_RAILS_ROOT,
#                              :singleton => true,
#                              :timeout => 90,
#                              :signal => 'INT')
# end