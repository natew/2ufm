set :output, "/var/www/2u.fm/web/shared/log/cron.log"
env :PATH, "#{ENV["PATH"]}:/usr/local/bin"

job_type :rake, "cd :path && RAILS_ENV=:environment bundle exec rake :task :output"

every 5.minutes do
  # rake "schedule:five_minutes"
end

every 30.minutes do
  rake "schedule:half_hour"
end

every 1.day do
  rake "schedule:daily"
end