class SongsController < ApplicationController
  def index
    @popular = Station.popular_station
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def create
    params[:song][:file] = UrlTempfile.new(params[:url])
    @song = Song.new(params[:song])
    
    respond_to do |format|
      if @song.save!
        format.html { render 'index' }
        format.js { render 'index', layout: false, notice: 'Posted song!' }
      else
        format.html { render 'index', notice: 'Could not post song!' }
        format.js { render 'index', layout: false }
      end
    end
  end
  
  def show
    @original = Song.find_by_slug(params[:id]) || not_found
    @songs    = Song.where(shared_id:@original.shared_id).individual
    @blogs    = Blog.joins(:songs).where('songs.shared_id = ? ', @original.shared_id)
    @stats    = Broadcast.find_by_sql("SELECT date_part('day', created_at), count(*) from broadcasts where song_id=#{@original.shared_id} group by date_part('day', created_at) order by date_part('day', created_at);").map {|x| [((Time.now.day - x.date_part.to_i).days.ago.to_f*1000).round,x.count.to_i]}
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def fresh
    @station = Station.new_station
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def failed
    @song = Song.find(params[:id])
    
    if @song
      @song.working = false
      @song.save
    end
    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
end