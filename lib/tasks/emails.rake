namespace :emails do
  namespace :send do
    task :daily_digest => :environment do
      puts 'Sending daily digest'
      User.with_privacy.receives_digests.each do |user|
        UserMailer.delay.daily_digest(user)
      end
    end
  end
end