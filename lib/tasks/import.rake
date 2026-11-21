require_relative '../recipe'
require_relative '../ba_ld_harvest'
require_relative '../ec_harvest'

namespace :import do
  desc 'Import a recipe from Bon Appétit (rake import:ba[URL])'
  task :ba, [:url] do |_t, args|
    Recipe.create!(BaLdHarvest.harvest(args[:url]))
  end

  desc 'Import a recipe from Epicurious (rake import:ec[URL])'
  task :ec, [:url] do |_t, args|
    Recipe.create!(EcHarvest.harvest(args[:url]))
  end
end
