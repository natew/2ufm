worker: bundle exec rake --trace jobs:work ENV=development
web: bundle exec thin start -p $PORT
pub: bundle exec rackup danthes.ru -s thin -E production
log: tail -f -n 0 log/development.log