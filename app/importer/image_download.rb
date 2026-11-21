require 'open-uri'
require 'digest'

# Saves a recipe's image into app/assets/images/recipes so pages serve a local
# copy instead of hotlinking the original host. Files are named by the MD5 of
# their content, so re-downloading the same image reuses the existing file.
class ImageDownload
  EXTENSIONS = {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/gif' => 'gif',
    'image/webp' => 'webp',
    'image/avif' => 'avif'
  }.freeze
  MAX_BYTES = 25.megabytes

  mattr_accessor :directory, default: Rails.root.join('app', 'assets', 'images', 'recipes')

  # Downloads the image at url and returns its asset path (e.g. "recipes/<md5>.jpg"),
  # or nil when there is no url.
  def self.fetch(url)
    return if url.blank?

    uri = URI.parse(url)
    raise ArgumentError, "Not an http(s) image URL: #{url}" unless uri.is_a?(URI::HTTP)

    too_big = ->(length) { raise ArgumentError, "Image is larger than #{MAX_BYTES} bytes: #{url}" if length && length > MAX_BYTES }
    uri.open(open_timeout: 10, read_timeout: 60, content_length_proc: too_big) do |io|
      store(io.read, io.content_type)
    end
  end

  # Writes bytes as <md5>.<ext> and returns the asset path.
  def self.store(bytes, content_type)
    extension = EXTENSIONS[content_type.to_s.split(';').first.to_s.strip.downcase]
    raise ArgumentError, "Unsupported image type: #{content_type.inspect}" unless extension

    name = "#{Digest::MD5.hexdigest(bytes)}.#{extension}"
    FileUtils.mkdir_p(directory)
    path = File.join(directory, name)
    File.binwrite(path, bytes) unless File.exist?(path)
    "recipes/#{name}"
  end
end
