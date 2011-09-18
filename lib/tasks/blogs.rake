namespace :blogs do
  task :update => :environment do
    Blog.all.each do |blog|
      blog.update_feed
    end
  end
end