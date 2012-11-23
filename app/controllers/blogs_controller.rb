class BlogsController < ApplicationController
  before_filter :is_admin?, :only => [:destroy]

  def index
    if params[:genre]
      @blogs = Station
                .has_songs(1)
                .joins('inner join blogs on blogs.id = stations.blog_id')
                .joins('inner join blogs_genres on blogs_genres.blog_id = blogs.id')
                .joins("inner join genres on genres.id = blogs_genres.genre_id")
                .where(genres: { slug: params[:genre] })
                .order('stations.songs_count desc')
                .page(params[:page])
                .per(Yetting.per)
    else
      @blogs = Station.blog_station.has_songs(1).order('random() desc').limit(12)
    end

    @blogs_genres = Hash[*
                      Station
                        .has_songs(1)
                        .where(blog_id: @blogs.map(&:blog_id))
                        .select("stations.blog_id as id, string_agg(genres.name, ', ') as blog_genres")
                        .joins('inner join blogs on blogs.id = stations.blog_id')
                        .joins('inner join blogs_genres on blogs_genres.blog_id = blogs.id')
                        .joins("inner join genres on genres.id = blogs_genres.genre_id")
                        .group('stations.blog_id')
                        .map{ |s| [s.id, s.blog_genres] }.flatten
                    ]

    @blogs.each do |station|
      station.content = @blogs_genres[station.blog_id]
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    @station  = Station.find_by_slug(params[:id])
    @playlist = { station: @station || not_found, songs: @station.songs.playlist_newest }
    @blog     = Blog.find(@station.blog_id) || not_found
    @artists  = Station.shelf.where(slug: @blog.station.artists.select('artists.station_slug').order('random() desc').limit(12).map(&:station_slug))
    @primary  = @blog

    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page @playlist }
    end
  end

  def popular
    @playlist = { station: Station.find_by_slug(params[:id]) || not_found, songs: @station.songs.playlist_rank }
    @blog     = Blog.find(@station.blog_id) || not_found
    @primary  = @blog

    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page @station, @songs }
    end
  end

  def new
    session[:blog_params] ||= {}
    @blog = Blog.new(session[:blog_params])

    respond_to do |format|
      format.html
    end
  end

  def create
    session[:blog_params].deep_merge!(params[:blog]) if params[:blog]
    @blog = Blog.new(session[:blog_params])
    @blog.active = false

    respond_to do |format|
      if verify_recaptcha(model: @blog, message: "Error with reCAPTCHA!") && @blog.save
        format.html { redirect_to '/', notice: "Thanks! Your submission will be reviewed and we will reply to you shortly." }
      else
        format.html { render action: 'new', notice: "We found a few errors submitting your blog" }
      end
    end
  end


  def edit
    @blog = Blog.find_by_slug(params[:id])
  end


  def update
    @blog = Blog.find_by_slug(params[:id])

    respond_to do |format|
      if @blog.update_attributes(params[:blog])
        format.html { redirect_to @blog, notice: 'Blog was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blogs/1
  # DELETE /blogs/1.json
  def destroy
    @blog = Blog.find_by_slug(params[:id])
    @blog.destroy

    respond_to do |format|
      format.html { redirect_to blogs_url }
      format.json { head :ok }
    end
  end
end
