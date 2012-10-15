class BlogsController < ApplicationController
  before_filter :is_admin?, :only => [:destroy]

  def index
    if params[:letter]
      letter = params[:letter]
      letter = "0-9" if letter == '0'
      @blogs = Blog.where("name ~* '^[#{letter}]'").order('name desc')
    else
      @blogs = Blog.order('random() desc').limit(12)
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    @station = Station.find_by_slug(params[:id]) || not_found
    @blog    = Blog.find(@station.blog_id) || not_found
    @posts   = @blog.posts.order('created_at desc').limit(8)
    @artists = @blog.station.artists.order('random() desc').limit(12)
    @primary = @blog

    respond_to do |format|
      format.html { render 'show' }
      format.page { render_page @blog.station }
    end
  end

  def new
    session[:blog_params] ||= {}
    @blog = Blog.new(session[:blog_params])
    @blog.current_step = session[:blog_step]

    respond_to do |format|
      format.html
    end
  end


  def create
    session[:blog_params].deep_merge!(params[:blog]) if params[:blog]
    @blog = Blog.new(session[:blog_params])
    @blog.current_step = session[:blog_step]

    if @blog.valid?
      if params[:back_button]
        @blog.previous_step
      elsif @blog.last_step?
        @blog.save if @blog.all_valid?
      else
        @blog.next_step
      end
      session[:blog_step] = @blog.current_step
    end

    respond_to do |format|
      if @blog.new_record?
        format.html { render 'new' }
      else
        session[:blog_step] = session[:blog_params] = nil
        flash[:notice] = "Blog saved!"
        redirect_to @blog
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
