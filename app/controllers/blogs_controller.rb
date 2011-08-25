class BlogsController < ApplicationController

  def index
    @blogs = Blog.page(params[:page]).per(24)
    @genres = Genre.all

    respond_to do |format|
      format.html # index.html.erb
      format.js { render :layout => false }
      format.json { render json: @blogs }
    end
  end

  def show
    @blog = Blog.find_by_slug(params[:id])
    @songs = @blog.songs.joins(:post, :blog).page(params[:page]).per(8)
    @queued_songs = @blog.songs.where("songs.artist = ''")
    @posts = @blog.posts.order('created_at desc').limit(8)
    @station = @blog.station
    
    for post in @posts
      logger.info post.title
    end
  
    respond_to do |format|
      format.html # show.html.erb
      format.js { render :layout => false }
      format.json { render json: @blog }
    end
  end


  def new
    session[:blog_params] ||= {}
    @blog = Blog.new(session[:blog_params])
    @blog.current_step = session[:blog_step]

    respond_to do |format|
      format.html # new.html.erb
      format.js { render :layout => false }
      format.json { render json: @blog }
    end
  end


  def create
    @blog = Blog.new(params[:blog])
    
    if @blog.valid?
      if params[:back_button]
        @blog.previous_step
      elsif @blog.last_step?
        redrect_to @blog if @blog.all_valid?
      else
        @blog.next_step if @blog.save
      end
      
      respond_to do |format|
        format.html { render 'new', :layout => false }
      end
    else
      respond_to do |format|
        format.html { render 'new', :layout => false }
      end
    end
  end
  
  
  def edit
    @blog = Blog.find(params[:id])
  end


  def update
    @blog = Blog.find(params[:id])

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
