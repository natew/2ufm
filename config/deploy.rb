# Bundler
require "bundler/capistrano"

# Pretty colors
require 'capistrano_colors'

# Assets
load 'deploy/assets'

# Whenever
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

default_run_options[:pty] = true

set :user, "nwienert"
set :application, "2u"
set :domain, "199.36.105.18"
set :repository,  "ssh://nwienert@199.36.105.18/var/git/#{application}.git"
set :deploy_to, "/var/www/#{application}.fm/web"
set :scm, :git
set :branch, 'master'
set :scm_verbose, false
set :rails_env, "production"
set :keep_releases, 3
set :dj_workers, 3
set :dj_script, "cd #{current_path}; RAILS_ENV=#{rails_env} nice -n 15 script/delayed_job -n #{dj_workers} --pid-dir=#{deploy_to}/shared/dj_pids"
set :danthes_start, "RAILS_ENV=production bundle exec rackup danthes.ru -s thin -E production -D -P tmp/pids/danthes.pid"
set :danthes_stop, "if [ -f tmp/pids/danthes.pid ] && [ -e /proc/$(cat tmp/pids/danthes.pid) ]; then kill -9 `cat tmp/pids/danthes.pid`; fi"

role :web, domain
role :app, domain
role :db,  domain, :primary => true # This is where Rails migrations will run

after 'deploy:update_code', 'deploy:migrate'
after 'deploy:update', 'deploy:symlink_attachments'
after 'deploy:update', 'deploy:symlink_tmp'
after 'deploy:update', 'deploy:clear_caches'
after 'deploy:update', 'deploy:cleanup'

# Run rake tasks
def run_rake(task, options={}, &block)
  command = "cd #{latest_release} && /usr/bin/env bundle exec rake #{task}"
  run(command, options, &block)
end

# Runs +command+ as root invoking the command with su -c
# and handling the root password prompt.
def surun(command)
  run("su - -c '#{command}'") do |channel, stream, output|
    channel.send_data("#{password}\n") if output
  end
end

namespace :deploy do
  task :start, :roles => :app do
    surun "cd #{current_path};RAILS_ENV=production bundle exec thin start -C config/thin.yml && #{danthes_start} && #{dj_script} start"
    #danthes.start
  end

  task :stop, :roles => :app do
    surun "cd #{current_path};RAILS_ENV=production bundle exec thin stop -C config/thin.yml && #{danthes_stop} && #{dj_script} stop >/dev/null 2>&1"
    #danthes.stop
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    surun "cd #{current_path};RAILS_ENV=production bundle exec thin restart -C config/thin.yml && #{danthes_stop} && #{danthes_start} && #{dj_script} restart >/dev/null 2>&1"
    #danthes.restart
  end

  task :symlink_attachments do
    run "ln -nfs #{shared_path}/attachments #{release_path}/public/attachments"
  end

  task :symlink_tmp do
    run "rm -rf #{release_path}/tmp"
    run "ln -nfs #{shared_path}/tmp #{release_path}/tmp"
    run "chmod 775 #{shared_path}/tmp"
  end

  task :clear_caches do
    run_rake "tmp:cache:clear >/dev/null 2>&1"
  end
end

namespace :cache do
  task :clear do
    run_rake "cache:clear"
  end
end

namespace :dj do
  task :restart do
    surun "cd #{current_path}; #{dj_script} restart"
  end
end

namespace :danthes do
  desc "Start danthes server"
  task :start do
    run "cd #{current_path}; #{danthes_start}"
  end

  desc "Stop danthes server"
  task :stop do
    run "cd #{current_path}; #{danthes_stop}"
  end

  desc "Restart danthes server"
  task :restart do
    stop
    start
  end
end