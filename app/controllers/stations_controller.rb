class StationsController < ApplicationController
  def index
    @stations = Station.where('user_id is null').order('updated_at desc').page(params[:page]).per(8)
    @genres = Genre.all

    respond_to do |format|
      format.html # index.html.erb
      format.js { render :layout => false }
      format.json { render json: @stations }
    end
  end

  def show
    @station = Station.find_by_slug(params[:id])
    @songs = @station.songs.processed.page(params[:page]).per(@per[:station])

    respond_to do |format|
      format.html # show.html.erb
      format.js { render :layout => false }
      format.json { render json: @station }
    end
  end
  
  def new
    @station = Station.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @station }
    end
  end

  def edit
    @station = Station.find_by_slug(params[:id])
  end

  def create
    @station = Station.new(params[:station])

    respond_to do |format|
      if @station.save
        format.html { redirect_to @station, notice: 'Station was successfully created.' }
        format.json { render json: @station, status: :created, location: @station }
      else
        format.html { render action: "new" }
        format.json { render json: @station.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @station = Station.find_by_slug(params[:id])
    
    songs = params[:song_ids].collect {|id| id.to_i} if params[:song_ids]
    seen = params[:seen_ids].collect {|id| id.to_i} if params[:seen_ids]
    
    remove = @station.songs.where(:id => seen)
    @station.songs.delete(remove) if remove
    
    add = Song.where(:id => songs)
    @station.songs<<(add)

    respond_to do |format|
      if @station.update_attributes(params[:station])
        format.html { redirect_to @station, notice: 'Station was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @station.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stations/1
  # DELETE /stations/1.json
  def destroy
    @station = Station.find(params[:id])
    @station.destroy

    respond_to do |format|
      format.html { redirect_to stations_url }
      format.json { head :ok }
    end
  end
end
