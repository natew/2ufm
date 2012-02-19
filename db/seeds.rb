# Delete old data
Blog.destroy_all
Station.destroy_all
Broadcast.destroy_all
User.destroy_all
Genre.destroy_all
Artist.destroy_all

# Delete old jobs
`rake jobs:clear`

# Default stations
Station.connection.execute("SELECT setval('stations_id_seq',1);") # Reset ID sequence
Station.create!(:description => 'Popular')
Station.create!(:description => 'New')

# Create blogs
blogs = [
  {:url => 'http://bassdownload.com', :name => 'BassDownload' },
  {:url => 'http://thefilth.us', :name => 'The Filth' },
  {:url => 'http://earmilk.com', :name => 'EarMilk' },
  {:url => 'http://thissongissick.com/blog/', :name => 'ThisSongIsSick' },
  {:url => 'http://dubstepremix.org/', :name => 'Dubstep Remix' },
  {:url => 'http://musicformorons.com/', :name => 'Music for Morons' },
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
  puts "Creating blog #{blog[:name]}"
  b = Blog.new(blog)
  begin
    b.image = File.open("#{Rails.root}/tmp/images/album#{(i%4)+1}.png")
  rescue
    puts "Error using image"
  end
  b.save
end


# Create Genres
Genre.create(:name => "Drum & Bass")
Genre.create(:name => "Dubstep")
Genre.create(:name => "House")
Genre.create(:name => "Electonic")
Genre.create(:name => "R&B")
Genre.create(:name => "Hip-Hop")
Genre.create(:name => "Electro")
Genre.create(:name => "Pop")
Genre.create(:name => "Trance")
Genre.create(:name => "Raggae")
Genre.create(:name => "Techno")
Genre.create(:name => "Rock")
Genre.create(:name => "Folk")
Genre.create(:name => "Indie")
Genre.create(:name => "Mashup")