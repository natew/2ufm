namespace :posts do
  task :get_images => :environment do
    puts 'Getting images'
    Post.all.each do |post|
      puts "Post #{post.name}"
      post.get_image
      post.save
    end
  end
end