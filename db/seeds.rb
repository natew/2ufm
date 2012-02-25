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
Station.create!(:title => 'Popular songs')
Station.create!(:title => 'New songs')

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
  {:url => 'http://eatenbymonsters.wordpress.com/', :name => 'Eaten By Monsters' },
  {:url => 'http://chemicaljump.com/', :name => 'Chemical Jump' },
  {:url => 'http://findtheshit.com/', :name => 'Find The Shit' },
  {:url => 'http://thissongslaps.com/', :name => 'This Song Slaps' },
  {:url => 'http://gottadancedirty.com/', :name => 'Gotta Dance Dirty' },
  {:url => 'http://remix-nation.com/', :name => 'Remix Nation' },
  {:url => 'http://www.thisisthebigbeat.com/', :name => 'This Is The Big Beat' },
  {:url => 'http://www.yourmusicradar.com/', :name => 'Your Music Radar' },
  {:url => 'http://thegetdownnn.wordpress.com/', :name => 'The Get Down' },
  {:url => 'http://92bpm.com/', :name => '92bpm' },
  {:url => 'http://kickkicksnare.com/', :name => 'KickKickSnare' },
  {:url => 'http://sunsetintherearview.com/', :name => 'Sunset In The Rearview' },
  {:url => 'http://www.weallwantsomeone.org/', :name => 'We All Want Someone To Shout For' },
  {:url => 'http://werun.nyheter24.se/', :name => 'First Up!' },
  {:url => 'http://stereogum.com/', :name => 'Stereo Gum' },
  {:url => 'http://www.whitefolksgetcrunk.com/', :name => 'White Folks Get Crunk' },
  {:url => 'http://indietoday.net/', :name => 'Indie Today' },
  {:url => 'http://survivingthegoldenage.com/', :name => 'Surviving The Golden Age' },
  {:url => 'http://www.chubbybeavers.com/', :name => 'Chubby Beavers' },
  {:url => 'http://giganticclub.com/', :name => 'Gigantic Club' },
  {:url => 'http://www.vacayvitamins.com/', :name => 'Vacay Vitamins' },
  {:url => 'http://www.lagasta.com/', :name => 'La Gasta' },
  {:url => 'http://themusic.fm/', :name => 'TheMusic.fm' },
  {:url => 'http://www.aerialnoise.com/', :name => 'Aerial Noise' },
  {:url => 'http://www.gorillavsbear.net/', :name => 'Gorilla vs Bear' },
  {:url => 'http://www.thelineofbestfit.com/', :name => 'The Line of Best Fit' },
  {:url => 'http://www.clubbing9ine.com/blog/', :name => 'Clubbing9ne' },
  {:url => 'http://www.bangerzonly.com/', :name => 'Bangerz Only' },
  {:url => 'http://acidted.wordpress.com/', :name => 'AcidTed' },
  {:url => 'http://thevinylvillain.blogspot.com/', :name => 'The Vinyl Villain' },
  {:url => 'http://www.phuturelabs.com/', :name => 'Phuture Labs' },
  {:url => 'http://www.nevver.com/', :name => 'Nevver' },
  {:url => 'http://boyattractions.com/', :name => 'Boy Attractions' },
  {:url => 'http://music.metafilter.com/', :name => 'Metafilter Music' },
  {:url => 'http://www.scatterblog.com/', :name => 'ScatterBlog' },
  {:url => 'http://www.teenagevulture.com/', :name => 'Teenage Vulture' },
  {:url => 'http://www.inthedeepend.com.au/', :name => 'In The Deep End' }
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
Genre.create(:name => "Electo")
Genre.create(:name => "R&B")
Genre.create(:name => "Hip-Hop")
Genre.create(:name => "Downtempo")
Genre.create(:name => "Pop")
Genre.create(:name => "Trance")
Genre.create(:name => "Progressive")
Genre.create(:name => "Techno")
Genre.create(:name => "Rock")
Genre.create(:name => "Folk")
Genre.create(:name => "Indie")
Genre.create(:name => "Mashup")