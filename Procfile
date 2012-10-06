worker: bundle exec rake --trace jobs:work ENV=development
web: bundle exec thin start -p $PORT
log: tail -f -n 0 log/development.log