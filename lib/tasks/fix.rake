namespace :fix do
  # Warning! Deletes everything!
  task :reset => :environment do
    blogs = Blog.all.map { |blog| {name:blog.name,url:blog.url} }
    #Blog.destroy_all
    
  end
  
  task :all => :environment do
    # todo
  end
end