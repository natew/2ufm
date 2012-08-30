class UpdateGenres < ActiveRecord::Migration
  def up
    Genre.create(name: 'Moombahton')
    Genre.create(name: 'Rap')
    Genre.create(name: 'Alternative')
  end

  def down
  end
end
