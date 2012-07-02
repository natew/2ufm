class UpdateGenres < ActiveRecord::Migration
  def up
    g = Genre.find_by_slug('electo')
    g.name = 'Electro'
    g.slug = 'electro'

    Genre.create(name: 'Moombahton')
    Genre.create(name: 'Rap')
    Genre.create(name: 'Alternative')
  end

  def down
  end
end
