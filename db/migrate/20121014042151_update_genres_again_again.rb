class UpdateGenresAgainAgain < ActiveRecord::Migration
  def up
    Genre.find_or_create_by_name('Techno').destroy
    Genre.create(name:'Rock')
  end

  def down
  end
end
