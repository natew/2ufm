class AddWaveformToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :waveform_file_name, :string
    add_column :songs, :waveform_updated_at, :datetime
  end
end
