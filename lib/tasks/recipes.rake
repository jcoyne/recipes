namespace :recipes do
  desc 'Download a local copy of the image for recipes that do not have one yet'
  task download_images: :environment do
    Recipe.all.each do |recipe|
      next if recipe.image.present? || recipe.thumbnail.blank?

      recipe.image = ImageDownload.fetch(recipe.thumbnail)
      recipe.save!
      puts "#{recipe.id}: #{recipe.image}"
    end
  end
end
