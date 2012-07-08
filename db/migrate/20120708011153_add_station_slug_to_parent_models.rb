class AddStationSlugToParentModels < ActiveRecord::Migration
  def change
    add_column :users, :station_slug, :string
    add_column :artists, :station_slug, :string
    add_column :blogs, :station_slug, :string
  end
end
