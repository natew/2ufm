class MainController < ApplicationController
  def index
    @blogs = Blog.limit(10)
    @stations = Station.limit(10)
    @artists = Artist.limit(10)
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def search
    render :text => '<li>Result1</li><li>Result2</li>'
  end
  
  def popular
    cols   = Song.column_names.collect {|c| "songs.#{c}"}.join(",")
    where  = " WHERE games.created_at > '#{params[:within].to_i.days.ago.to_s(:db)}'" unless params[:within].nil?
    
    @songs = Song.find_by_sql "SELECT songs.*, count(favorites.id) as favorites_count FROM songs INNER JOIN favorites on favorites.favorable_id = songs.id and favorites.favorable_type = 'Song'#{where} GROUP BY favorites.favorable_id, #{cols} ORDER BY favorites_count DESC LIMIT 21"
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
end
