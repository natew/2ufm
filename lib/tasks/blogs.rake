namespace :blogs do
  task :update => :environment do
    Blog.all.each do |blog|
      puts "Updating #{blog.name}"
      blog.get_new_posts
    end
  end
  
  task :create => :environment do
    blogs = [
      {:url => 'http://getoffthecoast.blogspot.com/', :name => 'Get off the Coast' },
      {:url => 'http://coverlaydown.com/', :name => 'Cover Lay Down' },
      {:url => 'http://causeequalstime.com/', :name => 'Cause=Time' },
      {:url => 'http://winniecooper.net/', :name => 'Winnie Cooper' },
      {:url => 'http://www.gorillavsbear.net/', :name => 'Gorilla vs. Bear' },
      {:url => 'http://yesgoodmusic.com/', :name => 'Yes Good Music' },
      {:url => 'http://pastaprima.net/', :name => 'Pasta Primavera' },
      {:url => 'http://eatenbymonsters.wordpress.com/', :name => 'Eaten By Monsters' }
    ]
    
    blogs.each_with_index do |blog,i|
      b = Blog.new(blog)
      begin
        b.image = File.open("#{Rails.root}/tmp/images/album#{(i%4)+1}.png")
      rescue
        puts "Error using image"
      end
      b.save
    end
  end
end