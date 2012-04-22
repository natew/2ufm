# Bundler
require "bundler/capistrano"

# Assets
load 'deploy/assets'

# Whenever
set :whenever_command, "bundle exec whenever"
set :job_template, nil
require "whenever/capistrano"

default_run_options[:pty] = true

set :user, "nwienert"
set :application, "2u"
set :domain, "199.36.105.18"
set :repository,  "ssh://nwienert@199.36.105.18/var/git/#{application}.git"
set :deploy_to, "/var/www/#{application}.fm/web"
set :scm, :git
set :branch, 'master'
set :scm_verbose, true
set :rails_env, "production"
set :keep_releases, 3
set :dj_workers, 4
set :dj_script, "cd #{current_path}; RAILS_ENV=#{rails_env} nice -n 15 script/delayed_job -n #{dj_workers} --pid-dir=#{deploy_to}/shared/dj_pids"

role :web, domain
role :app, domain
role :db,  domain, :primary => true # This is where Rails migrations will run

after 'deploy:update', 'deploy:cleanup'
after 'deploy:update', 'deploy:symlink_attachments'
after 'deploy:update', 'deploy:symlink_tmp'
after 'deploy:update', 'deploy:clear_cache'

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
    run "#{dj_script} start"
  end

  task :stop, :roles => :app do
    run "#{dj_script} stop"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
    run "#{dj_script} restart"
  end

  task :symlink_attachments do
    run "ln -nfs #{shared_path}/attachments #{release_path}/public/attachments"
  end

  task :symlink_tmp do
    run "cp -r #{release_path}/tmp/* #{shared_path}/tmp; rm -rf #{release_path}/tmp; ln -nfs #{shared_path}/tmp #{release_path}/tmp"
  end

  task :clear_cache do
    set :rake_cmd, "tmp:cache:clear"
    rake_exec
  end
end