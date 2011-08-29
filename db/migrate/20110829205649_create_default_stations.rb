class CreateDefaultStations < ActiveRecord::Migration
  def change
    Station.create!(:name => 'Popular Songs', :description => 'Most popular songs right now')
    Station.create!(:name => 'New Songs', :description => 'Newest songs')
  end
end
