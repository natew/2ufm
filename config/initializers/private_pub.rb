Thread.new do
  `bundle exec thin start --port 9292 --rackup private_pub.ru`
end