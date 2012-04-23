class Array
  def to_playlist
    self.map do |s|
      {:id => s.id, :artist => s.artist_name, :name => s.name, :url => s.url, :image => s.resolve_image(:small) } if s.processed?
    end.compact.to_json
  end
end

module ApplicationHelper
  # Station follow
  def follow_station(station)
    has    = current_user.following_station?(station.id) if user_signed_in?
    action = has ? "remove" : "add"
    id     = has ? current_user.follows.where(:station_id => station.id).first.id : station.id
    render :partial => "stations/follow", :locals => { :action => action, :id => id, :count => station.follows.size, :changed => false }
  end

  # Song broadcast
  def broadcast_song(song)
    has    = current_user.broadcasted_song?(song) if user_signed_in?
    action = has ? "remove" : "add"
    id     = has ? current_user.station.broadcasts.where(:song_id => song.shared_id).first.id : song.id
    render :partial => "songs/broadcast", :locals => { :action => action, :id => id, :count => song.broadcasts.count }
  end

  # Render artists for a song
  def links(models)
    links = []
    models.each do |model|
      links.push link_to(model.name, model)
    end
    raw links.join(', ')
  end

  # Render a link with the artists highlighted by type
  def title_with_artist_links(song)
    title = song.full_name

    # GSub bad stuff
    keywords = /www\.\S*|\S*\.com|featuring |ft(\.| )|feat(\.| )|f\.| remix| rmx\.?|produced by|prod\.? by/i
    title = title.gsub(keywords,' ').gsub(/\s{2}/,' ')

    # Replace authors with links
    song.authors.each do |author|
      title = highlight_artist(title, author.artist, author.role)
    end

    title.html_safe
  end

  def highlight_artist(string, artist, role)
    string.gsub(/#{artist.name}/,link_to(artist.name,artist,:class => "role role-#{role}"))
  end

  # Self explanitory
  def on_own_profile?
    user_signed_in? and controller.controller_name == 'users' and params[:id] == current_user.slug
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
        time_ago_in_words(return_date).gsub(/about/,'') + " ago"
      else
        year = return_date.year != Time.now.year ? ', %Y' : ''
        return_date.strftime("%b #{return_date.day.ordinalize}#{year}")
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
