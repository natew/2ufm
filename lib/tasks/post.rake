STDOUT.sync = true

namespace :posts do
  task :get_images => :environment do
    puts 'Getting images'
    Post.all.each do |post|
      puts "Post #{post.name}"
      post.get_image
      post.save
    end
  end

  task :rescan_within, [:within] => :environment do |t, args|
    unless args.within.nil?
      amount, period = args.within.split(".")
      puts "Rescanning posts within #{amount}.#{period}"
      Post.within(amount.to_i.send(period)).each do |post|
        print "."
        post.delayed_save_songs
      end
    end
  end
end