class AddFailuresToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :failures, :integer
  end
end
