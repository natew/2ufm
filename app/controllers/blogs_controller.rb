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
    
    if params[:spider] == 'true'
      @blog.feed = nil
      @blog.posts.delete_all
      @blog.songs.delete_all
      @blog.save
      
      params[:feed] = 'true'
      params[:songs] = 'true'
    end
    
    if params[:feed] == 'true'  
      logger.info 'FEED = TRUE'
      # Find feed url
      if @blog.feed_url.nil?
        @blog.update_attribute(:feed_url, find_blog_feed(@blog.url))
      end
      
      # Fetch or Update feed
      if @blog.feed.nil?
        feed      = Feedzirra::Feed.fetch_and_parse(@blog.feed_url)
        entries   = feed.entries
        feed_save_posts(entries)
      else
        feed      = Feedzirra::Feed.update(@blog.feed)
        if feed.updated?
          entries = feed.new_entries
          feed_save_posts(entries) 
        else
          flash[:notice] = 'No new entries'
        end
      end
      
      # Update feed in db
      @blog.update_attributes(
        :feed_updated_at => feed.last_modified,
        :feed            => feed
      )      
    end
    
    @posts = @blog.posts
    
    if params[:songs] == 'true'
      logger.info 'SONGS = TRUE'
#      @posts.each do |post|
#        post.save_songs
#      end
      Post.first.save_songs
    end
  
    @songs = @blog.songs.where("songs.slug != ''")

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @blog }
    end
  end
  
  def feed_save_posts(posts)
    posts.each do |post|
      # Save posts to db
      @blog.posts.create(
          :title => post.title,
          :author => post.author,
          :url => post.url,
          :content => post.content
        )
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
  
  private
  
  def find_blog_feed(url)
    html = Nokogiri::HTML(open(url))
    feed = html.at('head > link[type = "application/rss+xml"]')['href']
  end
end
