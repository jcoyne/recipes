source 'https://rubygems.org'
ruby '~> 4.0'

# Tooling for importing recipes into site/. The site itself is static files.
gem 'base64'
gem 'nokogiri'
gem 'rake'
# Shrinks and re-encodes downloaded recipe images (requires libvips with AVIF support)
gem 'ruby-vips'

group :development, :test do
  gem 'minitest'
  # rake serve
  gem 'webrick'
end
