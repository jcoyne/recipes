require 'test_helper'
require_relative '../lib/harvest'

class HarvestTest < Minitest::Test
  SHARE_URL = 'https://cooking.nytimes.com/recipes/1023634-duchess-style-twice-baked-potatoes?unlocked_article_code=abc&smid=share'.freeze

  def html(head)
    Nokogiri::HTML("<html><head>#{head}</head></html>")
  end

  def test_link_for_uses_the_canonical_url
    page = html('<link rel="canonical" href="https://cooking.nytimes.com/recipes/1023634-duchess-style-twice-baked-potatoes">')
    assert_equal 'https://cooking.nytimes.com/recipes/1023634-duchess-style-twice-baked-potatoes', Harvest.link_for(page, SHARE_URL)
  end

  def test_link_for_resolves_a_relative_canonical_url
    page = html('<link rel="canonical" href="/recipes/1023634">')
    assert_equal 'https://cooking.nytimes.com/recipes/1023634', Harvest.link_for(page, SHARE_URL)
  end

  def test_link_for_falls_back_to_the_given_url
    assert_equal SHARE_URL, Harvest.link_for(html(''), SHARE_URL)
    assert_equal SHARE_URL, Harvest.link_for(html('<link rel="canonical" href="javascript:alert(1)">'), SHARE_URL)
    assert_equal SHARE_URL, Harvest.link_for(html('<link rel="canonical" href="http://[bad">'), SHARE_URL)
  end
end
