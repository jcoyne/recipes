require 'test_helper'

class ImageDownloadTest < ActiveSupport::TestCase
  setup do
    @original_directory = ImageDownload.directory
    ImageDownload.directory = Dir.mktmpdir
  end

  teardown do
    FileUtils.rm_rf(ImageDownload.directory)
    ImageDownload.directory = @original_directory
  end

  def jpeg(width, height)
    Vips::Image.black(width, height, bands: 3).add(128).cast(:uchar).jpegsave_buffer
  end

  def stored(asset_path)
    File.join(ImageDownload.directory, File.basename(asset_path))
  end

  test 'store shrinks the image to the max width, encodes AVIF, and names it by the MD5 of the result' do
    asset_path = ImageDownload.store(jpeg(2400, 1200), 'image/jpeg')
    bytes = File.binread(stored(asset_path))
    image = Vips::Image.new_from_buffer(bytes, '')

    assert_equal "recipes/#{Digest::MD5.hexdigest(bytes)}.avif", asset_path
    assert_equal 'heifload_buffer', image.get('vips-loader')
    assert_equal [1200, 600], [image.width, image.height]
  end

  test 'store does not enlarge small images' do
    image = Vips::Image.new_from_file(stored(ImageDownload.store(jpeg(800, 600), 'image/jpeg')))
    assert_equal [800, 600], [image.width, image.height]
  end

  test 'store ignores content type parameters and case' do
    assert_match(/\.avif\z/, ImageDownload.store(jpeg(10, 10), 'Image/JPEG; charset=binary'))
  end

  test 'store rejects content that is not a supported image' do
    assert_raises(ArgumentError) { ImageDownload.store('<html>', 'text/html') }
    assert_raises(Vips::Error) { ImageDownload.store('not really a jpeg', 'image/jpeg') }
    assert_empty Dir.children(ImageDownload.directory)
  end

  test 'fetch returns nil without a url and rejects non-http urls' do
    assert_nil ImageDownload.fetch(nil)
    assert_raises(ArgumentError) { ImageDownload.fetch('/etc/passwd') }
    assert_raises(ArgumentError) { ImageDownload.fetch('file:///etc/passwd') }
  end
end
