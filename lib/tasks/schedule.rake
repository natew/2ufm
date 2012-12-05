namespace :schedule do
  task :half_hour => :environment do
    ac = ActionController::Base.new
    ac.expire_fragment('main_index_songs')
    ac.expire_fragment('main_index')
  end

  task :hourly => :environment do
    Rake::Task["blogs:update:all"].execute
  end

  task :five_minutes => :environment do
    # Expire caches
    # ac = ActionController::Base.new
    # ac.expire_fragment(/playlist_/)
  end

  task :daily => :environment do
    # Rake::Task["emails:send:daily_digest"].execute
    Rails.cache.clear
  end
end