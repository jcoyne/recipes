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
