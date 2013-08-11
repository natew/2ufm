require 'torquebox-capistrano-support'
require 'bundler/capistrano'
require 'capistrano_colors'
load 'deploy/assets'

# rbenv and ssh forwarding
set :default_environment, { 'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH" }
set :default_run_options, { :pty => true, :shell => '/bin/zsh' }
set :ssh_options, { :forward_agent => true }

set :scm_verbose, true
set :scm, :git
set :branch, 'master'

set :keep_releases, 2
set :use_sudo, false
set :deploy_via, :remote_cache

set :user, "nwienert"
set :application, "2u"
set :domain, "192.241.239.173"
set :repository,  "ssh://#{user}@#{domain}/var/git/#{application}.git"
set :deploy_to, "/var/www/#{application}/web"
set :rails_env, "production"

# DJ
set :dj_workers, 3
set :dj_script, "cd #{current_path}; RAILS_ENV=#{rails_env} nice -n 15 script/delayed_job -n #{dj_workers} --pid-dir=#{deploy_to}/shared/dj_pids"

# Danthes
set :danthes_start, "RAILS_ENV=#{rails_env} bundle exec rackup danthes.ru -s thin -E #{rails_env} -D -P tmp/pids/danthes.pid"
set :danthes_stop, "if [ -f tmp/pids/danthes.pid ] && [ -e /proc/$(cat tmp/pids/danthes.pid) ]; then kill -9 `cat tmp/pids/danthes.pid`; fi"

# Production server
set :torquebox_home,    "/opt/torquebox/current"
set :jboss_init_script, "/etc/init.d/jboss-as-standalone"
set :app_context,       "/"

# Whenever
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

# Roles
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

namespace :deploy do
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