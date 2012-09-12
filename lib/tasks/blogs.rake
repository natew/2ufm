STDOUT.sync = true

namespace :blogs do
  task :list => :environment do
    Blog.all.each do |blog|
      puts "#{blog.id} | #{blog.name}"
    end
  end

  task :get_post_format, [:id] => :environment do
    return if args.id.nil?
    blog = Blog.find(args.id.to_i)
    unless blog.nil?

    end
  end

  namespace :crawl do
    task :one, [:id] => :environment do |t, args|
      return if args.id.nil?
      blog = Blog.find(args.id.to_i)
      unless blog.nil?
        puts "Crawling #{blog.name}"
        blog.delayed_crawl
      end
    end

    task :all => :environment do
      Blog.all.each do |blog|
        puts "Crawling #{blog.name}"
        blog.delayed_crawl
      end
    end
  end

  task :set_screenshots => :environment do
    Blog.all.each do |blog|
      puts "Getting screenshot for #{blog.name}"
      blog.set_screenshot
      blog.save
    end
  end

  namespace :update do
    task :all => :environment do
      puts "Updating blogs at #{Time.now.to_s(:long)}"
      Blog.all.each_with_index do |blog, i|
        print i.to_s + " "
        blog.delayed_get_new_posts
      end

      # Clear popular every 30 minutes
      expire_fragment('playlist_popular')
      expire_fragment('playlist_new')
    end

    task :one, [:id] => :environment do |t, args|
      return if args.id.nil?
      blog = Blog.find(args.id.to_i)
      unless blog.nil?
        puts "Updating #{blog.name}"
        blog.delayed_get_new_posts
        puts "Done"
      end
    end
  end

  task :reset_feeds => :environment do
    Blog.all.each do |blog|
      blog.reset_feed
    end
  end

  task :reset, [:blog] => :environment do |t,args|
    blog = Blog.find_by_slug(args.blog)
    blog.reset
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