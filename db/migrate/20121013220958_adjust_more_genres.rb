class AdjustMoreGenres < ActiveRecord::Migration
  def up
    Genre.find_or_create_by_name('Mashup').destroy
    Genre.find_or_create_by_name('Experimental').destroy
    Genre.find_or_create_by_name('Moombahton').destroy
    Genre.find_or_create_by_name('Oldies').destroy
    Genre.find_or_create_by_name('Trap').destroy

    Genre.create(name:'Alternative')
    Genre.create(name:'Reggae')
    Genre.create(name:'Experimental')
  end

  def down
  end
end
