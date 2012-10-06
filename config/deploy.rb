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

role :web, domain
role :app, domain
role :db,  domain, :primary => true # This is where Rails migrations will run

after 'deploy:update', 'deploy:symlink_attachments'
after 'deploy:update', 'deploy:symlink_tmp'
after 'deploy:update', 'deploy:clear_caches'

# Run rake tasks
def run_rake(task, options={}, &block)
  command = "cd #{latest_release} && /usr/bin/env bundle exec rake #{task}"
  run(command, options, &block)
end

# Runs +command+ as root invoking the command with su -c
# and handling the root password prompt.
def surun(command)
  password = fetch(:root_password, Capistrano::CLI.password_prompt("Root Password: "))
  run("su - -c '#{command}'") do |channel, stream, output|
    channel.send_data("#{password}\n") if output
  end
end

namespace :deploy do
  task :start, :roles => :app do
    surun "cd #{current_path}; bundle exec service thin start && #{dj_script} start"
    private_pub.start
  end

  task :stop, :roles => :app do
    surun "cd #{current_path}; bundle exec service thin stop && #{dj_script} stop >/dev/null 2>&1"
    private_pub.stop
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    surun "cd #{current_path}; bundle exec service thin restart && #{dj_script} restart >/dev/null 2>&1"
    private_pub.restart
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
    # run_rake "songs:clear_cache"
  end
end

namespace :private_pub do
  desc "Start private_pub server"
  task :start do
    run "cd #{current_path};RAILS_ENV=production bundle exec rackup private_pub.ru -s thin -E production -D -P tmp/pids/private_pub.pid"
  end

  desc "Stop private_pub server"
  task :stop do
    run "cd #{current_path};if [ -f tmp/pids/private_pub.pid ] && [ -e /proc/$(cat tmp/pids/private_pub.pid) ]; then kill -9 `cat tmp/pids/private_pub.pid`; fi"
  end

  desc "Restart private_pub server"
  task :restart do
    stop
    start
  end
end