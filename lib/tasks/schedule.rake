namespace :schedule do
  task :half_hour => :environment do
    # Update blogs
    Rake::Task["blogs:update:all"].execute
  end

  task :five_minutes => :environment do
    # Expire caches
    ac = ActiveSupport::Cache::MemoryStore.new
    ac.expire_fragment(/^playlist/)
  end
end