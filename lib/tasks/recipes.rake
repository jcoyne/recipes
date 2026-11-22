require_relative '../recipe'
require_relative '../image_download'

SITE_DIR = File.expand_path('../../site', __dir__)

namespace :recipes do
  desc 'Download a local copy of the image for recipes that do not have one yet'
  task :download_images do
    Recipe.all.each do |recipe|
      next if recipe.image || recipe.thumbnail.nil?

      recipe.image = ImageDownload.fetch(recipe.thumbnail)
      recipe.save!
      puts "#{recipe.id}: #{recipe.image}"
    end
  end

  desc "Set a recipe's list section, and optionally whether it's vegetarian " \
       "(rake 'recipes:categorize[pasta-salad,Salads,no]')"
  task :categorize, [:id, :category, :vegetarian] do |_t, args|
    category = Recipe::CATEGORIES.find { |name| name.casecmp?(args[:category].to_s) } or
      abort "Category must be one of: #{Recipe::CATEGORIES.join(', ')}"
    recipe = Recipe.find(args[:id])
    recipe.category = category
    case args[:vegetarian]
    when nil, '' then nil
    when /\A(y|yes|true)\z/i then recipe.vegetarian = true
    when /\A(n|no|false)\z/i then recipe.vegetarian = false
    else abort 'Vegetarian must be yes or no'
    end
    recipe.save!
    puts "#{recipe.id}: #{recipe.category}#{', vegetarian' if recipe.vegetarian}"
  end

  desc "Add a keyword to recipes (rake 'recipes:tag[Thanksgiving,sausage-stuffing-recipe,pasta-salad]')"
  task :tag, [:keyword] do |_t, args|
    keyword = args[:keyword].to_s.strip
    abort 'Usage: rake recipes:tag[Keyword,recipe-id,...]' if keyword.empty? || args.extras.empty?

    args.extras.each do |id|
      recipe = Recipe.find(id)
      # Reuse the existing spelling of a keyword, so "thanksgiving" doesn't split off from "Thanksgiving".
      existing = Recipe.all.flat_map(&:keywords).find { |k| k.casecmp?(keyword) } || keyword
      next puts("#{id}: already has #{existing}") if recipe.keywords.any? { |k| k.casecmp?(existing) }

      recipe.keywords = (recipe.keywords + [existing]).sort_by(&:downcase)
      recipe.save!
      puts "#{id}: #{recipe.keywords.join(', ')}"
    end
  end

  desc "Remove a keyword from recipes (rake 'recipes:untag[Thanksgiving,pasta-salad]')"
  task :untag, [:keyword] do |_t, args|
    abort 'Usage: rake recipes:untag[Keyword,recipe-id,...]' if args[:keyword].to_s.strip.empty? || args.extras.empty?

    args.extras.each do |id|
      recipe = Recipe.find(id)
      recipe.keywords = recipe.keywords.reject { |k| k.casecmp?(args[:keyword].strip) }
      recipe.save!
      puts "#{id}: #{recipe.keywords.empty? ? 'no keywords' : recipe.keywords.join(', ')}"
    end
  end

  desc 'Rebuild site/recipes/index.json from the recipe files'
  task :index do
    Recipe.write_index
  end
end

desc 'Serve site/ at http://localhost:8000 (PORT=... to change)'
task :serve do
  require 'webrick'

  port = Integer(ENV.fetch('PORT', 8000))
  mime_types = WEBrick::HTTPUtils::DefaultMimeTypes.merge('avif' => 'image/avif', 'b64' => 'text/plain')
  server = WEBrick::HTTPServer.new(Port: port, DocumentRoot: SITE_DIR, MimeTypes: mime_types)
  trap('INT') { server.shutdown }
  puts "Serving #{SITE_DIR} at http://localhost:#{port}/"
  server.start
end

desc 'Copy site/ to ../jcoyne.github.io/recipes (DEPLOY_DIR=... to change); commit and push there to publish'
task :deploy do
  target = File.expand_path(ENV.fetch('DEPLOY_DIR', '../jcoyne.github.io/recipes'), __dir__ + '/../..')
  abort "#{File.dirname(target)} does not exist" unless Dir.exist?(File.dirname(target))

  sh 'rsync', '-a', '--delete', '--exclude', '.DS_Store', "#{SITE_DIR}/", "#{target}/"
  puts "Copied site/ to #{target}"
end
