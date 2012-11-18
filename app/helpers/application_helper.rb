# Application Helper
module ApplicationHelper
  def title
    title = ["2u.fm"]
    page_title = @title || (@primary and @primary.get_title) || (@listen_song and @listen_song.full_name) || controller.controller_name.capitalize
    title.unshift page_title if page_title
    title.join(' | ')
  end

  def body_classes
    if user_signed_in?
      classes = ['signed_in']
      classes.push 'new_user' if current_user.first_time?
    else
      classes = ['signed_out']
    end

    classes.push("theme-body-1 theme-head-1")
    classes.push(Rails.env)
    classes.join(' ')
  end

  def ad_spot(size, controller)
    ad = Ad.where(size: size).active.first
    if ad
      yield raw render text: ad.code
    end
  end

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

  def english_number(number)
    words = {
      0 => 'zero',
      1 => 'one',
      2 => 'two',
      3 => 'three',
      4 => 'four',
      5 => 'five',
      6 => 'six',
      7 => 'seven',
      8 => 'eight',
      9 => 'nine',
      10 => 'ten',
      11 => 'eleven',
      12 => 'twelve',
      13 => 'thirteen',
      14 => 'fourteen',
      15 => 'fifteen',
      16 => 'sixteen',
      17 => 'seventeen',
      18 => 'eighteen',
      19 => 'nineteen',
      20 => 'twenty'
    }

    words[number]
  end

  def js_date(time)
    time = time.class == String ? Date.parse(time) : time
    time.strftime("%Y-%m-%d %H:%M:%S GMT%z")
  end

  # based on https://github.com/rails/rails/blob/f78cb5583f77952aa35e063a660a11aad5f8de7f/activesupport/lib/active_support/cache.rb#L486
  def cache_key(key)
    return key.cache_key.to_s if key.respond_to?(:cache_key)

    case key
    when Array
      if key.size > 1
        key = key.collect{|element| cache_key(element)}
      else
        key = key.first
      end
    when Hash
      key = key.sort_by { |k,_| k.to_s }.collect{|k,v| "#{k}=#{v}"}
    end

    key.to_param
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
    render :partial => 'stations/station', :collection => collection, :locals => { :nocache => true }.merge(locals)
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

  def nav_link_to(title, path, *options)
    options = options.size > 0 ? options[0] : {}
    class_active = on_current_page?(path) ? 'active' : ''
    link_to title, path, options.merge({ :class => class_active })
  end

  def on_current_page?(resource)
    url_for(resource) == request.path.gsub(/\/p-[0-9]+/, '')
  end

  # Render artists for a song
  def author_links(authors)
    list = []
    original = []
    authors.with_artist.each do |author|
      link = link_to(author.artist_name, station_path(author.artist_station_slug), :class => "role role-#{author.role}") unless author.artist_station_slug.nil?
      if author.role == 'original'
        original.push(link)
      else
        author.role == 'remix' ? list.unshift(link) : list.push(link)
      end
    end

    if original.empty?
      original = list
      list = []
    end

    { :original => raw(original.join(' ')), :other => raw(list.join(' ')) }
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
    when 1000..1000000
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