class BlogsController < ApplicationController

  def index
    @blogs = Blog.order('created_at desc').page(params[:page]).per(9)

    respond_to do |format|
      format.html # index.html.erb
      format.js { render :layout => false }
    end
  end

  def show
    @blog = Blog.find_by_slug(params[:id]) || not_found
    @posts = @blog.posts.order('created_at desc').limit(8)
    @artists = @blog.station.artists.limit(20)

    respond_to do |format|
      format.html # show.html.erb
      format.js { render :layout => false }
    end
  end


  def new
    session[:blog_params] ||= {}
    @blog = Blog.new(session[:blog_params])
    @blog.current_step = session[:blog_step]

    respond_to do |format|
      format.html # new.html.erb
      format.js { render :layout => false }
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
        format.js { render 'new', :layout => false }
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
