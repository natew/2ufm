class ChangeStationDescriptionToTitle < ActiveRecord::Migration
  def change
  	change_column :stations, :description, :string
  	rename_column :stations, :description, :title
  end
end
