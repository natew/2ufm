class CreateFollows < ActiveRecord::Migration
  def change
    create_table :follows do |t|
      t.references :station, :user
    end
  end
end
