# Application Helper
module ApplicationHelper
  # Station follow
  def follow_station(station)
    station = Station.find(station.to_i) if station.kind_of?(String)
    id      = station.id
    has     = current_user.following_station?(id) if user_signed_in?
    action  = has ? "remove" : "add"
    follow  = has ? current_user.follows.where(:station_id => id).first.id : id
    render :partial => "stations/follow", :locals => { :action => action, :id => follow, :count => station.follows.size, :changed => false }
  end

  # Song broadcast
  def broadcast_song(song)
    if user_signed_in? and current_user.broadcasted_song?(song)
      action = "remove"
      id = current_user.station.broadcasts.where(:song_id => song.shared_id).first.id
    else
      action = "add"
      id = song.id
    end

    render :partial => "songs/broadcast", :locals => { :action => action, :id => id, :count => song.user_broadcasts_count }
  end

  def seconds_to_time(seconds)
    s = seconds % 60
    m = seconds / 60
    h = (m % 60).to_s + 'h ' if m > 60
    "#{h}#{m}m #{s}s"
  end

  # Render artists for a song
  def links(models)
    links = []
    models.each do |model|
      links.push link_to(model.name, model)
    end
    raw links.join(', ')
  end

  # Render artists for a song
  def author_links(authors)
    list = []
    authors = authors.joins(:artist)
    authors.each do |author|
      link = link_to(author.artist.name, author.artist, :class => 'role role-' + author.role)
      author.role == 'original' ? list.unshift(link) : list.push(link)
    end
    raw list.join(', ')
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

  def abbreviated_number(number)
    case number
    when 0...1000
      number
    when 1000...1000000
      (number / 1000.00).round(1).to_s + 'k'
    when 1000000...1000000000
      (number / 1000000.00).round(1).to_s + 'm'
    else
      number_with_delimiter number
    end
  end

  # Returns time_ago_in_words within two weeks, otherwise formatted date
  def relative_time(date)
    begin
      return_date = date.to_time
      if (return_date > 1.minute.ago)
        "just now"
      elsif (return_date > 2.weeks.ago)
        time_ago_in_words(return_date).gsub(/about/,'') + ' ago'
      else
        year = return_date.year != Time.now.year ? ', %Y' : ''
        return_date.strftime("%b #{return_date.day.ordinalize}#{year}")
      end
    rescue
      'pending'
    end
  end

  # Returns time for songs
  def song_time(seconds)
    Time.at(seconds).gmtime.strftime('%R:%S').gsub(/00\:/,'')
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


# Array Helper
class Array
  def to_playlist
    self.map do |s|
      {:id => s.id, :artist_name => s.artist_name, :name => s.name, :url => s.url, :image => s.resolve_image(:small) } if s.processed?
    end.compact.to_json
  end
end
