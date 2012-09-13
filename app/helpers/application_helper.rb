# Application Helper
module ApplicationHelper
  # Station follow
  def follow_station(id, follows_count, options={})
    action = "add"
    options[:nocache] ||= false
    action = "remove" if options[:nocache] and user_signed_in? and current_user.following_station?(id)
    render :partial => "stations/follow", :locals => { :action => action, :id => id, :count => follows_count, :changed => false }
  end

  # Song broadcast
  def broadcast_song(song)
    action = "add"
    # action = "remove" if user_signed_in? and current_user.broadcasted_song?(song)
    render :partial => "songs/broadcast", :locals => { :action => action, :id => song.matching_id, :count => song.user_broadcasts_count }
  end

  def seconds_to_time(seconds)
    s = seconds % 60
    m = seconds / 60
    h = (m % 60).to_s + 'h ' if m > 60
    "#{h}#{m}m #{s}s"
  end

  def js_date(time)
    time.strftime("%Y-%m-%dT%H:%M:%S")
  end

  def cache_if(condition, name = {}, &block)
    if condition
      cache(name, &block)
    else
      yield
    end
    return nil
  end

  def render_stations(collection, locals = {})
    render :partial => 'stations/station', :collection => collection, :locals => locals
  end

  # Render artists for a song
  def links(models)
    links = []
    models.each do |model|
      links.push link_to(model.name, model)
    end
    raw links.join(', ')
  end

  def tagged_song_name(name)
    name.gsub(/([\(\[][^\(\)\[\]]+[\)\]])|((featuring | ?ft\.? |feat\.? |f\. |w\/).*)/i,'').html_safe
  end

  def nav_link_to(title, path)
    class_active = current_page?(path) ? 'active' : ''
    link_to title, path, :class => class_active
  end

  # Render artists for a song
  def author_links(authors)
    list = []
    original = []
    authors.with_artist.each do |author|
      tip = author.role == 'original' ? '' : 'tip-n'
      link = link_to(author.artist_name, station_path(author.artist_station_slug), :class => "#{tip} role role-#{author.role}", :title => author.role.capitalize) unless author.artist_station_slug.nil?
      if author.role == 'original'
        original.push(link)
      else
        author.role == 'remix' ? list.unshift(link) : list.push(link)
      end
    end
    { :original => raw(original.join(', ')), :other => raw(list.join(', ')) }
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
      if (return_date > 2.weeks.ago)
        time_ago_in_words(return_date)
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
      {:id => s.matching_id, :artist_name => s.artist_name, :name => s.name, :image => s.resolve_image(:small) } if s.processed?
    end.compact.to_json
  end
end
