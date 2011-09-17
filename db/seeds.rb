# Delete old data
Blog.destroy_all
Station.destroy_all
Favorite.destroy_all
User.destroy_all
Genre.destroy_all

# Delete old jobs
`rake jobs:clear`

# Default stations
Station.create!(:name => 'Popular Songs', :description => 'Most popular songs right now')
Station.create!(:name => 'New Songs', :description => 'Newest songs')

# Create blogs
blog = [
  {:url => 'http://bassdownload.com', :name => 'BassDownload' },
  {:url => 'http://thefilth.us', :name => 'The Filth' },
  {:url => 'http://earmilk.com', :name => 'EarMilk' },
  {:url => 'http://thissongissick.com/blog/', :name => 'ThisSongIsSick' },
  {:url => 'http://themusicninja.com', :name => 'Music Ninja' }
]


i = 0
while i < 5
  b = Blog.new(blog[i])
  begin
    b.image = File.open("#{Rails.root}/tmp/images/album#{(i%4)+1}.png")
  rescue
  end
  b.save
  i += 1
end


# Create Genres
Genre.create(:name => "Drum & Bass")
Genre.create(:name => "Dubstep")
Genre.create(:name => "House")
Genre.create(:name => "Electonic")
Genre.create(:name => "R&B")
Genre.create(:name => "Hip-Hop")
Genre.create(:name => "House")
Genre.create(:name => "Pop")
Genre.create(:name => "Trance")
Genre.create(:name => "Raggae")
Genre.create(:name => "Techno")
Genre.create(:name => "Rock")
Genre.create(:name => "Folk")
Genre.create(:name => "Indie")
Genre.create(:name => "Mashup")