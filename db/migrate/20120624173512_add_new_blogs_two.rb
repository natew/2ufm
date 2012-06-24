class AddNewBlogsTwo < ActiveRecord::Migration
  def up
    blogs = [
      { :url => 'http://bedwettingcosmonaut.com/',
        :name => 'bedwetting cosmonaut' },
      { :url => 'http://www.lechoix.fr/',
        :name => 'Le Choix' },
      { :url => 'http://www.friendswithbotharms.com/',
        :name => 'Friends With Both Arms' },
      { :url => 'http://www.musikmigblidt.dk/',
        :name => 'Music Mig Blidt' },
      { :url => 'http://hillydilly.com/',
        :name => 'Hilly Dilly' },
      { :url => 'http://eclecticeavesdroppings.tumblr.com/',
        :name => 'Eclectic Eavesdroppings' },
      { :url => 'http://www.newmusicco.com/',
        :name => 'New Music Collaborative',
        :url => 'http://indiemusicfilter.com/',
        :name => 'Indie Music Filter' },
      { :url =>  'http://www.tellallyourfriendsmusic.com/',
        :name => 'tell all your friends' },
      { :url =>  'http://allthingsgomusic.com/',
        :name => 'All Things Go' },
      { :url =>  'http://www.reviler.org/',
        :name => 'Reviler' },
      { :url =>  'http://blog.minneapolisfuckingrocks.com/',
        :name => 'Minneapolis Fucking Rocks' },
      { :url =>  'http://www.thewordisbond.com/',
        :name => 'Word Is Bond' },
      { :url =>  'http://thefourohfive.com/',
        :name => '405' },
      { :url =>  'http://poponandon.com/',
        :name => 'Pop And On' },
      { :url =>  'http://potholesinmyblog.com/',
        :name => 'Potholes in my Blog' },
      { :url =>  'http://www.prefixmag.com/',
        :name => 'Prefix' },
      { :url =>  'http://different-kitchen.com/',
        :name => 'Different Kitchen' },
      { :url =>  'http://klubbace.se/',
        :name => 'Ace' },
      { :url =>  'http://www.listenbeforeyoubuy.net/',
        :name => 'Listen Before Your Buy' },
      { :url =>  'http://www.musiclikedirt.com/',
        :name => 'Music Like Dirt' },
      { :url =>  'http://dippedindollars.com/',
        :name => 'Dipped In Dollars' },
      { :url =>  'http://www.abeano.com/',
        :name => 'Abeano' },
      { :url =>  'http://www.waxhole.blogspot.com/',
        :name => 'Waxhole' },
      { :url =>  'http://www.portalsmusic.com/',
        :name => 'Portals' },
      { :url =>  'http://www.indieforbunnies.com/',
        :name => 'Indie for Bunnies' },
      { :url =>  'http://www.indierockcafe.com/',
        :name => 'indie rock cafe' },
      { :url =>  'http://adventuresofamusicsnob.tumblr.com/',
        :name => 'Adventures of a Music Snob' },
      { :url =>  'http://passionweiss.com/',
        :name => 'Passion of the Weiss' },
      { :url =>  'http://www.thepopsucker.com/',
        :name => 'The Pop Sucker' },
      { :url =>  'http://ourvinyl.com/',
        :name => 'Our Vinyl' },
      { :url =>  'http://www.deadhorsemarch.com/',
        :name => 'Dead Horse March' },
      { :url =>  'http://www.buffablog.com/',
        :name => 'BuffaBLOG' },
      { :url =>  'http://quietrebel.com/',
        :name => 'Quiet Rebel' },
      { :url =>  'http://seainhd.com/',
        :name => 'Seattle in High Def' }
    ]


    blogs.each do |blog|
      puts "Creating blog #{blog[:name]}"
      Blog.delay.create(blog)
    end
  end

  def down
  end
end