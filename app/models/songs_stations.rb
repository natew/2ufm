class SongsStations < ActiveRecord::Base
  belongs_to :station
  belongs_to :song
end
