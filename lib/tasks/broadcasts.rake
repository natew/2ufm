namespace :broadcasts do
  task :set_parent => :environment do
    Broadcast.all.each do |broadcast|
      broadcast.set_parent
      broadcast.save
    end
  end
end