require 'test_helper'
require_relative '../lib/ld_harvest'

class LdHarvestTest < Minitest::Test
  URL = 'https://example.com/recipes/kalpudding'.freeze

  def page(*blocks)
    scripts = blocks.map { |block| %(<script type="application/ld+json">#{block.to_json}</script>) }.join
    Nokogiri::HTML("<html><head>#{scripts}</head><body></body></html>")
  end

  def recipe(overrides = {})
    {
      '@context' => 'https://schema.org', '@type' => 'Recipe', 'name' => 'Kalpudding',
      'recipeYield' => '4 servings', 'recipeIngredient' => ['1 head cabbage', '3 tablespoons molasses'],
      'recipeInstructions' => [{ '@type' => 'HowToStep', 'text' => 'Heat oven to 350.' },
                               { '@type' => 'HowToStep', 'text' => 'Bake.' }],
      'image' => 'https://example.com/a.jpg'
    }.merge(overrides)
  end

  def test_finds_the_recipe_among_several_json_ld_blocks
    attrs = LdHarvest.parse(page({ '@type' => 'WebPage' }, recipe, { '@type' => 'Organization' }), URL)

    assert_equal 'Kalpudding', attrs[:title]
    assert_equal URL, attrs[:link]
    assert_equal '4 servings', attrs[:servings]
    assert_equal ['1 head cabbage', '3 tablespoons molasses'], attrs[:ingredients]
    assert_equal ['Heat oven to 350.', 'Bake.'], attrs[:preparation_steps]
  end

  def test_finds_a_recipe_inside_a_graph_or_list
    assert_equal 'Kalpudding', LdHarvest.parse(page({ '@graph' => [{ '@type' => 'WebSite' }, recipe] }), URL)[:title]
    assert_equal 'Kalpudding', LdHarvest.parse(page([{ '@type' => 'WebSite' }, recipe]), URL)[:title]
  end

  def test_skips_unparseable_blocks
    html = Nokogiri::HTML(%(<script type="application/ld+json">{ not json</script>
                            <script type="application/ld+json">#{recipe.to_json}</script>))
    assert_equal 'Kalpudding', LdHarvest.parse(html, URL)[:title]
  end

  def test_raises_without_a_recipe
    assert_raises(ArgumentError) { LdHarvest.parse(page({ '@type' => 'WebPage' }), URL) }
  end

  def test_picks_the_widest_image_object
    images = [{ '@type' => 'ImageObject', 'contentUrl' => 'https://example.com/1600.jpg', 'width' => 1600 },
              { '@type' => 'ImageObject', 'url' => 'https://example.com/2048.jpg', 'width' => '2048' },
              { '@type' => 'ImageObject', 'contentUrl' => 'https://example.com/1050.jpg', 'width' => 1050 }]
    assert_equal 'https://example.com/2048.jpg', LdHarvest.parse(page(recipe('image' => images)), URL)[:thumbnail]
  end

  def test_takes_the_first_of_a_list_of_image_urls
    images = %w[https://example.com/16x9.jpg https://example.com/4x3.jpg]
    assert_equal 'https://example.com/16x9.jpg', LdHarvest.parse(page(recipe('image' => images)), URL)[:thumbnail]
  end

  def test_flattens_how_to_sections_and_splits_text_instructions
    sections = [{ '@type' => 'HowToSection', 'name' => 'Cabbage',
                  'itemListElement' => [{ '@type' => 'HowToStep', 'text' => 'Shred.' }] },
                { '@type' => 'HowToSection', 'name' => 'Meat',
                  'itemListElement' => [{ '@type' => 'HowToStep', 'text' => 'Mix.' }] }]
    assert_equal %w[Shred. Mix.], LdHarvest.parse(page(recipe('recipeInstructions' => sections)), URL)[:preparation_steps]
    assert_equal %w[Shred. Mix.], LdHarvest.parse(page(recipe('recipeInstructions' => "Shred.\n\nMix.")), URL)[:preparation_steps]
  end

  def test_cleans_up_html_in_text_and_picks_the_most_descriptive_yield
    attrs = LdHarvest.parse(page(recipe('name' => 'Salt &amp; Pepper', 'recipeYield' => ['4', '4 servings'],
                                        'recipeIngredient' => ['<b>1</b> cup flour'])), URL)
    assert_equal 'Salt & Pepper', attrs[:title]
    assert_equal '4 servings', attrs[:servings]
    assert_equal ['1 cup flour'], attrs[:ingredients]
  end
end
