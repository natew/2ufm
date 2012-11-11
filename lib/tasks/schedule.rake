namespace :schedule do
  task :half_hour => :environment do
    # Clear popular every 30 minutes
    expire_fragment('playlist_popular')
    expire_fragment('playlist_new')
    expire_fragment('main_index')

    Rake::Task["blogs:update:all"].execute
  end
end