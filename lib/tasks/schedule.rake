namespace :schedule do
  task :half_hour => :environment do
    # Update blogs
    Rake::Task["blogs:update:all"].execute
  end

  task :five_minutes => :environment do
    # Expire caches
    ac = ActionController::Base.new
    ac.expire_fragment('playlist_trending')
    ac.expire_fragment('playlist_popular')
    ac.expire_fragment('playlist_new')
  end
end