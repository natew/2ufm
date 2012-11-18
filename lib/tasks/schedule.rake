namespace :schedule do
  task :half_hour => :environment do
    ac = ActionController::Base.new

    # Expire caches
    ac.expire_fragment('playlist_popular')
    ac.expire_fragment('playlist_new')
    ac.expire_fragment('main_index_artists')
    ac.expire_fragment('main_index_sidebar')

    # Update blogs
    Rake::Task["blogs:update:all"].execute
  end
end