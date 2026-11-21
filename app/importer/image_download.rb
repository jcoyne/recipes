require 'open-uri'
require 'digest'
require 'vips'

# Saves a recipe's image into app/assets/images/recipes so pages serve a local
# copy instead of hotlinking the original host. Images are shrunk to at most
# MAX_WIDTH pixels wide and re-encoded as AVIF, then named by the MD5 of the
# result, so re-processing the same image reuses the existing file.
class ImageDownload
  ACCEPTED_TYPES = %w[image/jpeg image/png image/gif image/webp image/avif].freeze
  MAX_BYTES = 25.megabytes
  MAX_WIDTH = 1200
  AVIF_QUALITY = 35

  mattr_accessor :directory, default: Rails.root.join('app', 'assets', 'images', 'recipes')

  # Downloads the image at url and returns its asset path (e.g. "recipes/<md5>.avif"),
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

  # Shrinks and re-encodes the image bytes, writes them as <md5>.avif and returns the asset path.
  def self.store(bytes, content_type)
    type = content_type.to_s.split(';').first.to_s.strip.downcase
    raise ArgumentError, "Unsupported image type: #{content_type.inspect}" unless ACCEPTED_TYPES.include?(type)

    avif = encode(bytes)
    name = "#{Digest::MD5.hexdigest(avif)}.avif"
    FileUtils.mkdir_p(directory)
    path = File.join(directory, name)
    File.binwrite(path, avif) unless File.exist?(path)
    "recipes/#{name}"
  end

  # Resize to at most MAX_WIDTH wide (never enlarging; thumbnail also applies EXIF rotation)
  # and encode as AVIF without metadata.
  def self.encode(bytes)
    image = Vips::Image.thumbnail_buffer(bytes, MAX_WIDTH, height: 10_000, size: :down)
    image.heifsave_buffer(compression: :av1, Q: AVIF_QUALITY, effort: 4, keep: :none)
  end
end
