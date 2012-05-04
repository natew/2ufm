class AddNewBlogs < ActiveRecord::Migration
  def up
    blogs = [
      { :url => 'http://www.chromemusic.de/',
        :name => 'Chromemusic' },
      { :url => 'http://newonmyplaylist.com/',
        :name => 'New On My Playlist' },
      { :url => 'http://pigeonsandplanes.com/',
        :name => 'Pigeons and Planes' },
      { :url => 'http://niteversions.com/',
        :name => 'Nite Versions' },
      { :url => 'http://www.electricadolescence.com/',
        :name => 'Electric Adolescence' },
      { :url => 'http://this.bigstereo.net/',
        :name => 'Big Stereo' },
      { :url => 'http://bothbarson.wordpress.com/',
        :name => 'Both Bars On' }
    ]


    blogs.each do |blog|
      puts "Creating blog #{blog[:name]}"
      Blog.delay.create(blog)
    end
  end

  def down
  end
end
