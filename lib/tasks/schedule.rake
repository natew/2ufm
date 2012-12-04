namespace :schedule do
  task :half_hour => :environment do
    # Update blogs
    Rake::Task["blogs:update:all"].execute

    ac = ActionController::Base.new
    # ac.expire_fragment('main_index')
    ac.expire_fragment('main_index_songs')
  end

  task :five_minutes => :environment do
    # Expire caches
    # ac = ActionController::Base.new
    # ac.expire_fragment(/playlist_/)
  end

  task :daily => :environment do
    # Rake::Task["emails:send:daily_digest"].execute
    Rails.cache.clear

    ac = ActionController::Base.new
    ac.expire_fragment('main_index')
  end
end