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

  def test_picks_a_section_from_recipe_category
    {
      'Dinner, Main Course, Soup' => 'Soups & Stews',
      'Breakfast, Kid-Friendly, Main Course, Pancakes' => 'Breakfast',
      'Dinner, Side Dish, Vegetables' => 'Sides',
      ['Salad', 'Main Course'] => 'Salads',
      'Main Course, Side Dish, Vegetables' => 'Mains',
      'Dinner, Noodles' => 'Mains',
      'Desserts' => 'Desserts',
      'Noodles' => nil
    }.each do |recipe_category, section|
      attrs = LdHarvest.parse(page(recipe('recipeCategory' => recipe_category, 'keywords' => 'soup, dessert')), URL)
      section ? assert_equal(section, attrs[:category], recipe_category) : assert_nil(attrs[:category], recipe_category)
    end
  end

  def test_falls_back_to_keywords_without_a_recipe_category
    assert_equal 'Sides', LdHarvest.parse(page(recipe('keywords' => ['ba’s best', 'side', 'thanksgiving'])), URL)[:category]
    assert_nil LdHarvest.parse(page(recipe('keywords' => 'thanksgiving, potato')), URL)[:category]
    assert_nil LdHarvest.parse(page(recipe), URL)[:category]
  end

  def test_reads_vegetarian_from_suitable_for_diet
    assert LdHarvest.parse(page(recipe('suitableForDiet' => 'VegetarianDiet')), URL)[:vegetarian]
    assert LdHarvest.parse(page(recipe('suitableForDiet' => ['https://schema.org/VeganDiet'])), URL)[:vegetarian]
    refute LdHarvest.parse(page(recipe('suitableForDiet' => 'GlutenFreeDiet', 'keywords' => 'vegetarian')), URL)[:vegetarian]
  end

  def test_falls_back_to_vegetarian_keywords_without_suitable_for_diet
    assert LdHarvest.parse(page(recipe('keywords' => ['side', 'vegetarian'])), URL)[:vegetarian]
    refute LdHarvest.parse(page(recipe('keywords' => 'Vegetarian Thanksgiving')), URL)[:vegetarian]
    refute LdHarvest.parse(page(recipe), URL)[:vegetarian]
  end

  def test_trims_non_breaking_spaces
    attrs = LdHarvest.parse(page(recipe('name' => "Beans and Greens ", 'recipeIngredient' => ["1  cup flour"])), URL)
    assert_equal 'Beans and Greens', attrs[:title]
    assert_equal ['1 cup flour'], attrs[:ingredients]
  end
end
