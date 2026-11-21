require 'test_helper'

class ImageDownloadTest < Minitest::Test
  def setup
    @original_directory = ImageDownload.directory
    ImageDownload.directory = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(ImageDownload.directory)
    ImageDownload.directory = @original_directory
  end

  def jpeg(width, height)
    Vips::Image.black(width, height, bands: 3).add(128).cast(:uchar).jpegsave_buffer
  end

  def stored(asset_path)
    File.join(ImageDownload.directory, File.basename(asset_path))
  end

  def test_store_shrinks_the_image_to_the_max_width_encodes_avif_and_names_it_by_the_md5_of_the_result
    asset_path = ImageDownload.store(jpeg(2400, 1200), 'image/jpeg')
    bytes = File.binread(stored(asset_path))
    image = Vips::Image.new_from_buffer(bytes, '')

    assert_equal "images/#{Digest::MD5.hexdigest(bytes)}.avif", asset_path
    assert_equal 'heifload_buffer', image.get('vips-loader')
    assert_equal [1200, 600], [image.width, image.height]
  end

  def test_store_does_not_enlarge_small_images
    image = Vips::Image.new_from_file(stored(ImageDownload.store(jpeg(800, 600), 'image/jpeg')))
    assert_equal [800, 600], [image.width, image.height]
  end

  def test_store_ignores_content_type_parameters_and_case
    assert_match(/\.avif\z/, ImageDownload.store(jpeg(10, 10), 'Image/JPEG; charset=binary'))
  end

  def test_store_rejects_content_that_is_not_a_supported_image
    assert_raises(ArgumentError) { ImageDownload.store('<html>', 'text/html') }
    assert_raises(Vips::Error) { ImageDownload.store('not really a jpeg', 'image/jpeg') }
    assert_empty Dir.children(ImageDownload.directory)
  end

  def test_fetch_returns_nil_without_a_url_and_rejects_non_http_urls
    assert_nil ImageDownload.fetch(nil)
    assert_raises(ArgumentError) { ImageDownload.fetch('/etc/passwd') }
    assert_raises(ArgumentError) { ImageDownload.fetch('file:///etc/passwd') }
  end
end
