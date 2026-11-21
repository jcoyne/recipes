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

  test 'store names the file by the MD5 of its content with an extension from the content type' do
    bytes = 'fake jpeg bytes'
    md5 = Digest::MD5.hexdigest(bytes)

    assert_equal "recipes/#{md5}.jpg", ImageDownload.store(bytes, 'image/jpeg')
    assert_equal bytes, File.binread(File.join(ImageDownload.directory, "#{md5}.jpg"))
  end

  test 'store ignores content type parameters and case' do
    assert_match(/\.png\z/, ImageDownload.store('png', 'Image/PNG; charset=binary'))
  end

  test 'store rejects content that is not a supported image' do
    assert_raises(ArgumentError) { ImageDownload.store('<html>', 'text/html') }
    assert_empty Dir.children(ImageDownload.directory)
  end

  test 'fetch returns nil without a url and rejects non-http urls' do
    assert_nil ImageDownload.fetch(nil)
    assert_raises(ArgumentError) { ImageDownload.fetch('/etc/passwd') }
    assert_raises(ArgumentError) { ImageDownload.fetch('file:///etc/passwd') }
  end
end
