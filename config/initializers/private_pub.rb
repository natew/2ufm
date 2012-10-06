Thread.new do
  `rackup private_pub.ru -s thin -E production 2>&1 | tee -a log/development.log`
end