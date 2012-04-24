set :output, "/var/www/2u.fm/web/shared/log/cron.log"
env :PATH, "#{ENV["PATH"]}:/usr/local/bin"

job_type :rake, "cd :path && RAILS_ENV=:environment bundle exec rake :task :output"

every 30.minutes do
  rake "blogs:update:all"
end


# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end