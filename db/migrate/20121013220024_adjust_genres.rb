class AdjustGenres < ActiveRecord::Migration
  def up
    Genre.find_by_name('Electo').update_attributes(name:'Electro')
    Genre.find_by_name('Alternative').destroy
    Genre.find_by_name('Indie').update_attributes(name:'Indie Rock')
    Genre.find_by_name('Rock').update_attributes(name:'Classic Rock')

    Genre.create(name:'Experimental')
    Genre.create(name:'Indie Pop')
    Genre.create(name:'Jazz')
    Genre.create(name:'Trap')
    Genre.create(name:'Oldies')
  end

  def down
  end
end
