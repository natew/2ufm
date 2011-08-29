class GenresStations < ActiveRecord::Base
  belongs_to :genre
  belongs_to :station
end
