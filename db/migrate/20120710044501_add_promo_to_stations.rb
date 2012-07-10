class AddPromoToStations < ActiveRecord::Migration
  def change
    add_column :stations, :promo, :boolean, :default => false
  end
end
