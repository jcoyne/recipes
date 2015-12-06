namespace :import do
  desc 'Send some tweets to a user'
  task :ba, [:url] => [:environment] do |t, args|
    Recipe.create!(BaHarvest.harvest(args[:url]))
  end
end
