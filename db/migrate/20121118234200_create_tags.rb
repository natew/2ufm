class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, :type
      t.references :song
      t.timestamps
    end
  end
end
