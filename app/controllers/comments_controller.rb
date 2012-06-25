class CommentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @song = Song.find(params[:id])
    @comment = Comment.build_from( @song, current_user.id, params[:comment] )

    if @comment.save
      respond_to do |format|
        format.js { render :partial => 'comment' }
      end
    end
  end
end
