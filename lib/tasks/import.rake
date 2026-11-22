require_relative '../recipe'
require_relative '../ld_harvest'
require_relative '../ec_harvest'

def import_recipe(harvester, url)
  abort 'Usage: rake import:ld[URL]' if url.nil? || url.empty?

  recipe = Recipe.create!(harvester.harvest(url))
  puts "Imported #{recipe.id}: #{recipe.title} (#{recipe.ingredients.size} ingredients, " \
       "#{recipe.preparation_steps.size} steps, image #{recipe.image || 'none'})"
  puts "  Section: #{recipe.category || 'none (set with rake recipes:categorize)'}" \
       "#{', vegetarian' if recipe.vegetarian}"
end

namespace :import do
  desc "Import a recipe from any page with a schema.org Recipe in its JSON-LD (rake import:ld[URL])"
  task :ld, [:url] do |_t, args|
    import_recipe(LdHarvest, args[:url])
  end

  desc 'Import a recipe from Bon Appétit (same as import:ld)'
  task :ba, [:url] do |_t, args|
    import_recipe(LdHarvest, args[:url])
  end

  desc 'Import a recipe from Epicurious (rake import:ec[URL])'
  task :ec, [:url] do |_t, args|
    import_recipe(EcHarvest, args[:url])
  end
end
