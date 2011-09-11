module ApplicationHelper

  def Array.to_playlist
    self.map do |i|
      i.to_json
    end
  end

  # Song broadcast
  def song_broadcast(song)
    has    = current_user.broadcasted_song?(song) if user_signed_in?
    action = has ? "remove" : "add"
    id     = has ? current_user.station.broadcasts.where(:song_id => song.id).first.id : song.id
    render :partial => "songs/broadcast", :locals => { :action => action, :id => id, :count => song.broadcasts.size }
  end

  # Truncates the given text to the given length and appends truncate_string to the end if the text was truncated
  def truncate(text, options = {})
    length = options[:length] || 120
    truncate_string = options[:truncate_with] || "&hellip;".html_safe
    
    return if text.nil?
    text = (text.mb_chars.length > length) ? text[/\A.{#{length}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
    raw h(strip_tags(text))
  end
  
  # Returns time_ago_in_words within two weeks, otherwise formatted date
  def relative_time(date)
    begin
      return_date = date.to_time
      if (return_date > 2.weeks.ago)
        time_ago_in_words(return_date) + " ago"
      else
        return_date.strftime("%b #{return_date.day.ordinalize}, %Y")
      end
    rescue
      'pending'
    end
  end
  
  # Determines if a link is "active" and wraps in ".active" if so
  def link(*args)
    options         = args[1] || {}
    html_options    = args[2] || {}
    url             = url_for(options)
    active_options  = html_options.delete(:active) || {}

    html_options[:class] = 'active' if is_active_link?(url, active_options)

    link_to(args[0], options, html_options)
  end
  
  private
  
  def is_active_link?(url, options = {})
    case options[:when]
      when :self, nil
        !request.fullpath.match(/^#{Regexp.escape(url)}(\/?.*)?$/).blank?
      when :self_only
        !request.fullpath.match(/^#{Regexp.escape(url)}\/?(\?.*)?$/).blank?
      when Regexp
        !request.fullpath.match(options[:when]).blank?
      when Array
        controllers = options[:when][0]
        actions     = options[:when][1]
        (controllers.blank? || controllers.member?(params[:controller])) &&
        (actions.blank? || actions.member?(params[:action]))
      when TrueClass
        true
      when FalseClass
        false
      end
  end
end
