class ActiveRecord::Base
  def non_id_attributes
    atts = self.attributes
    atts.delete('id')
    atts
  end
end

class AddIndexToAuthors < ActiveRecord::Migration
  def change
		# duplicate_groups = Author.all.group_by { |element| element.non_id_attributes }.select{ |gr| gr.size > 1 }
		# redundant_elements = duplicate_groups.map { |group| group.last - [group.last.first] }.flatten
		# redundant_elements.each(&:destroy)

  	add_index :authors, [:artist_id, :song_id, :role], :unique => true
  end
end
