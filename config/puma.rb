#!/usr/bin/env puma

basedir = '/var/www/2u/web/current'

directory "#{basedir}"
environment 'production'
daemonize true

bind "unix://#{basedir}/tmp/puma/puma.sock"
pidfile "#{basedir}/tmp/puma/pid"
state_path "#{basedir}/tmp/puma/state"
#stdout_redirect "#{basedir}/shared/log/out.puma.log", "#{basedir}/shared/log/err.puma.log", false

threads 4, 24
workers 1
preload_app!

# on_worker_boot do
#   ActiveSupport.on_load(:active_record) do
#     ActiveRecord::Base.establish_connection
#   end
# end

# handled by init.d script
# activate_control_app "unix://#{basedir}/tmp/puma/control.sock"

# Disable request logging.
quiet

# Instead of “bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'” you
# can also use the “ssl_bind” option.
#
# ssl_bind '127.0.0.1', '9292', { key: path_to_key, cert: path_to_cert }

# Code to run before doing a restart. This code should
# close log files, database connections, etc.
#
# This can be called multiple times to add code each time.
#
# on_restart do
#   puts 'On restart...'
# end

# Command to use to restart puma. This should be just how to
# load puma itself (ie. 'ruby -Ilib bin/puma'), not the arguments
# to puma, as those are the same as the original process.
#
# restart_command '/u/app/lolcat/bin/restart_puma'

# === Puma control rack application ===

# Start the puma control rack application on “url”. This application can
# be communicated with to control the main server. Additionally, you can
# provide an authentication token, so all requests to the control server
# will need to include that token as a query parameter. This allows for
# simple authentication.
#
# Check out https://github.com/puma/puma/blob/master/lib/puma/app/status.rb
# to see what the app has available.
#
# activate_control_app 'unix:///var/run/pumactl.sock'
# activate_control_app 'unix:///var/run/pumactl.sock', { auth_token: '12345' }
# activate_control_app 'unix:///var/run/pumactl.sock', { no_token: true }