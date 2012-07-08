class UpdateStationSlugsOnParentModels < ActiveRecord::Migration
  def up
    User.all.each do |model|
      model.set_station_slug
      model.save
    end

    Artist.all.each do |model|
      model.set_station_slug
      model.save
    end

    Blog.all.each do |model|
      model.set_station_slug
      model.save
    end
  end

  def down
  end
end
