namespace :schedule do
  task :half_hour => :environment do
    Rake::Task["blogs:update:all"].execute

    # Clear popular every 30 minutes
    expire_fragment('playlist_popular')
    expire_fragment('playlist_new')
    expire_fragment('main_index')
  end
end