class AddMoreAndMoreBlogs < ActiveRecord::Migration
  def up
    if Rails.env == 'production'
      blogs = [
        { :url =>  'http://www.that-dj.com/',
          :name => 'That DJ' },
        { :url =>  'For the Love of House Music',
          :name => 'http://iluvhousemusic.blogspot.com/' },
        { :url =>  'http://www.trancemix.org/',
          :name => 'Trance Mix' },
        { :url =>  'http://pureblissvocals.blogspot.com/',
          :name => 'Pure Bliss Vocals' },
        { :url =>  'http://www.seekanddownload.com.au/',
          :name => 'Seek and Download' },
        { :url =>  'http://www.beatmyday.com/',
          :name => 'Beat my Day' },
        { :url =>  'http://toastandjamz.com/',
          :name => 'Toast and Jamz' },
        { :url =>  'Dirty Electro Sounds',
          :name => 'http://dirtyelectrosounds.com/' },
        { :url =>  'http://electrocloud.blogspot.com/',
          :name => 'Electro Cloud' },
        { :url =>  'http://digi10ve.com/',
          :name => 'digi10ve' },
        { :url =>  'http://dj-lounge.com/',
          :name => 'DJ Lounge' },
        { :url =>  'http://dml.fm/',
          :name => 'DML' },
        { :url =>  'http://www.boxmusique.com/',
          :name => 'Box Musique' },
        { :url =>  'http://lessthan3.com/',
          :name => 'LessThan3' },
        { :url =>  'http://i-love-edm.blogspot.com/',
          :name => 'I Love EDM' },
        { :url =>  'http://electrojams.com/',
          :name => 'ElectroJams' },
        { :url =>  'http://edm-blog.ch/',
          :name => 'EDM Blog' },
        { :url =>  'http://2000down.blogspot.com/',
          :name => '2000 Down' },
        { :url =>  'http://www.badmansound.com/',
          :name => 'BadManSound' },
        { :url =>  'http://www.beezo.net/',
          :name => 'Beezo' },
        { :url =>  'http://www.globaldancemusic.com/',
          :name => 'Global Dance Music' },
        { :url =>  'http://metrojolt.com/',
          :name => 'MetroJolt' },
        { :url =>  'http://metrojolt.com/',
          :name => 'Dancing Astronaut' },
        { :url =>  'http://www.bassdropper.blogspot.com/',
          :name => 'Bass Dropper' },
        { :url =>  'http://www.letsgofingmental.com/',
          :name => 'Lets Go Fing Mental' },
        { :url =>  'http://www.chooned.net/',
          :name => 'Chooned' }
      ]


      blogs.each do |blog|
        puts "Creating blog #{blog[:name]}"
        Blog.delay.create(blog)
      end
    end
  end

  def down
  end
end
