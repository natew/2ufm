class UpdateIncludesRemixColumn < ActiveRecord::Migration
  def up
    Genre.where(slug:['electo', 'drum-and-bass','dubstep','house','trance','progressive','alternative','experimental','downtempo']).each do |genre|
      genre.update_attributes(includes_remixes:true)
    end
  end

  def down
  end
end
