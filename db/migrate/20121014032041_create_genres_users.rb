class CreateGenresUsers < ActiveRecord::Migration
  def change
    create_table :genres_users do |t|
      t.references :genre, :user
    end
  end
end
