class AddExcerptToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :excerpt, :string

    # Post.all.each do |p|
    #   p.save
    # end
  end
end
