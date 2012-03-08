namespace :dj do
  task :clear_3 => :environment do
    Delayed::Job.find_by_priority(3).destroy
  end

  task :clear_2 => :environment do
    Delayed::Job.find_by_priority(2).destroy
  end

  task :clear_1 => :environment do
    Delayed::Job.find_by_priority(1).destroy
  end
end