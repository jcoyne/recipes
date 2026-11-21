namespace :recipes do
  desc 'Export recipes from the legacy recipes database table to data/recipes'
  task export: :environment do
    legacy = Class.new(ActiveRecord::Base) do
      self.table_name = 'recipes'
      serialize :ingredients, coder: JSON
      serialize :preparation_steps, coder: JSON

      def self.name = 'LegacyRecipe'
    end

    legacy.order(:id).find_each do |row|
      if Recipe.find_by_link(row.link)
        puts "skip   #{row.link} (already exported)"
        next
      end

      recipe = Recipe.create!(row.attributes.slice('title', 'link', 'thumbnail', 'servings', 'ingredients',
                                                    'preparation_steps', 'created_at'))
      puts "wrote  #{Recipe.path_for(recipe.id)}"
    end
  end
end
