namespace :import do
  desc 'Import from BA'
  task :ba, [:url] => [:environment] do |t, args|
    Recipe.create!(BaLdHarvest.harvest(args[:url]))
  end

  desc 'Import from EC'
  task :ec, [:url] => [:environment] do |t, args|
    Recipe.create!(EcHarvest.harvest(args[:url]))
  end
end
