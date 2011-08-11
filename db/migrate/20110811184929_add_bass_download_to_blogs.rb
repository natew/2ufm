class AddBassDownloadToBlogs < ActiveRecord::Migration
  def self.up
    Blog.create!(:url => 'http://bassdownload.com', :name => 'BassDownload')
  end
end
