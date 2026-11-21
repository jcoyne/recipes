require 'test_helper'

class RecipeTest < ActiveSupport::TestCase
  setup do
    @original_directory = Recipe.directory
    Recipe.directory = Dir.mktmpdir
  end

  teardown do
    FileUtils.rm_rf(Recipe.directory)
    Recipe.directory = @original_directory
  end

  def attrs(overrides = {})
    { title: 'Make-Ahead Gravy', link: 'https://example.com/gravy', servings: '8 servings',
      ingredients: ['1 Tbsp. oil'], preparation_steps: ['Heat oil.'] }.merge(overrides)
  end

  test 'create! writes a base64-encoded JSON file named after the title' do
    recipe = Recipe.create!(attrs)

    assert_equal 'make-ahead-gravy', recipe.id
    raw = File.read(File.join(Recipe.directory, 'make-ahead-gravy.b64'))
    refute_includes raw, 'Gravy'
    assert_equal 'Make-Ahead Gravy', JSON.parse(Base64.decode64(raw))['title']
  end

  test 'find round-trips the attributes' do
    Recipe.create!(attrs)
    recipe = Recipe.find('make-ahead-gravy')

    assert_equal ['1 Tbsp. oil'], recipe.ingredients
    assert_equal ['Heat oil.'], recipe.preparation_steps
    assert_equal '8 servings', recipe.servings
    assert recipe.persisted?
  end

  test 'find rejects unknown and unsafe ids' do
    assert_raises(ActiveRecord::RecordNotFound) { Recipe.find('nope') }
    assert_raises(ActiveRecord::RecordNotFound) { Recipe.find('../secrets') }
  end

  test 'titles that collide get a numeric suffix' do
    Recipe.create!(attrs)
    second = Recipe.create!(attrs(link: 'https://example.com/other-gravy'))

    assert_equal 'make-ahead-gravy-2', second.id
    assert_equal %w[make-ahead-gravy make-ahead-gravy-2], Recipe.all.map(&:id)
  end

  test 'the same link cannot be saved twice' do
    Recipe.create!(attrs)
    assert_raises(Recipe::DuplicateLink) { Recipe.create!(attrs(title: 'Other')) }
  end

  test 'normalized_ingredients flattens the older hash format' do
    recipe = Recipe.new(ingredients: [{ 'quantity' => '1', 'unit' => 'cup', 'name' => 'flour' }])
    assert_equal ['1 cup flour'], recipe.normalized_ingredients
  end
end
