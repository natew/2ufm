require 'nokogiri'
require 'open-uri'
require 'chronic'
require 'feedzirra'

class BlogsController < ApplicationController
  # GET /blogs
  # GET /blogs.json
  def index
    @blogs = Blog.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @blogs }
    end
  end

  def show
    @blog = Blog.find_by_slug(params[:id])
    
    if params[:posts] == 'delete'
      @blog.feed = nil
      @blog.posts.delete_all
      @blog.save
    end
    
    if params[:posts] == 'download'
      @blog.update_posts
    end
    
    if params[:feed] == 'update'
      @blog.update_feed
    end
    
    if params[:songs] == 'download'
      @blog.posts.first.save_songs
    end
    
    if params[:songs] or params[:posts] or params[:feed]
      redirect_to @blog
    else
      @songs = @blog.songs.where("songs.artist != ''").joins(:post, :blog).page(params[:page]).per(8)
      @queued_songs = @blog.songs.where("songs.artist = ''")
      @posts = @blog.posts.order('created_at desc').limit(8)
      @station = @blog.station
      
      for post in @posts
        logger.info post.title
      end
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @blog }
      end
    end
  end
  
  def find_date(doc)
    Chronic.parse(doc.css('.entry-date,.date').to_s)
  end
  
  def find_google_date(url)
    doc = Nokogiri::HTML(open("http://google.com/search?q=inurl:#{url}"))
    Chronic.parse(doc.at('#ires span.f.std').text)
  end

  # GET /blogs/new
  # GET /blogs/new.json
  def new
    @blog = Blog.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @blog }
    end
  end

  # GET /blogs/1/edit
  def edit
    @blog = Blog.find(params[:id])
  end

  # POST /blogs
  # POST /blogs.json
  def create
    @blog = Blog.new(params[:blog])

    respond_to do |format|
      if @blog.save
        format.html { redirect_to @blog, notice: 'Blog was successfully created.' }
        format.json { render json: @blog, status: :created, location: @blog }
      else
        format.html { render action: "new" }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /blogs/1
  # PUT /blogs/1.json
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
    @blog = Blog.find(params[:id])
    @blog.destroy

    respond_to do |format|
      format.html { redirect_to blogs_url }
      format.json { head :ok }
    end
  end
end
