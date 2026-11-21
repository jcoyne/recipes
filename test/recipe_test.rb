require 'test_helper'

class RecipeTest < Minitest::Test
  def setup
    @original_directory = Recipe.directory
    Recipe.directory = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(Recipe.directory)
    Recipe.directory = @original_directory
  end

  def attrs(overrides = {})
    { title: 'Make-Ahead Gravy', link: 'https://example.com/gravy', servings: '8 servings',
      ingredients: ['1 Tbsp. oil'], preparation_steps: ['Heat oil.'] }.merge(overrides)
  end

  def recipe_files
    Dir.children(Recipe.directory) - [Recipe::INDEX]
  end

  def index
    JSON.parse(File.read(File.join(Recipe.directory, Recipe::INDEX)))
  end

  def test_create_writes_a_base64_json_file_named_by_the_md5_of_its_contents
    recipe = Recipe.create!(attrs)

    assert_equal 'make-ahead-gravy', recipe.id
    assert_equal 1, recipe_files.size
    raw = File.read(File.join(Recipe.directory, recipe_files.first))
    assert_equal "#{Digest::MD5.hexdigest(raw)}.b64", recipe_files.first
    refute_includes raw, 'Gravy'
    decoded = JSON.parse(Base64.decode64(raw))
    assert_equal 'Make-Ahead Gravy', decoded['title']
    assert_equal 'make-ahead-gravy', decoded['id']
  end

  def test_saving_writes_an_index_of_files_oldest_first
    first = Recipe.create!(attrs(created_at: '2026-01-01 00:00:00 UTC'))
    second = Recipe.create!(attrs(title: 'Biscuits', link: 'https://example.com/biscuits', created_at: '2025-01-01 00:00:00 UTC'))

    assert_equal [File.basename(second.path), File.basename(first.path)], index
  end

  def test_saving_a_change_renames_the_file_keeps_the_id_and_updates_the_index
    Recipe.create!(attrs)
    recipe = Recipe.find('make-ahead-gravy')
    old_path = recipe.path

    recipe.servings = '4 servings'
    recipe.save!

    refute File.exist?(old_path)
    assert_equal [File.basename(recipe.path)], recipe_files
    assert_equal [File.basename(recipe.path)], index
    assert_equal '4 servings', Recipe.find('make-ahead-gravy').servings
  end

  def test_find_round_trips_the_attributes
    Recipe.create!(attrs)
    recipe = Recipe.find('make-ahead-gravy')

    assert_equal ['1 Tbsp. oil'], recipe.ingredients
    assert_equal ['Heat oil.'], recipe.preparation_steps
    assert_equal '8 servings', recipe.servings
    assert recipe.persisted?
  end

  def test_find_rejects_unknown_ids
    assert_raises(Recipe::NotFound) { Recipe.find('nope') }
    assert_raises(Recipe::NotFound) { Recipe.find('../secrets') }
  end

  def test_titles_that_collide_get_a_numeric_suffix
    Recipe.create!(attrs)
    second = Recipe.create!(attrs(link: 'https://example.com/other-gravy'))

    assert_equal 'make-ahead-gravy-2', second.id
    assert_equal %w[make-ahead-gravy make-ahead-gravy-2], Recipe.all.map(&:id).sort
  end

  def test_the_same_link_cannot_be_saved_twice
    Recipe.create!(attrs)
    assert_raises(Recipe::DuplicateLink) { Recipe.create!(attrs(title: 'Other')) }
  end

  def test_slugify
    assert_equal 'ba-s-best-mashed-potatoes', Recipe.slugify('BA’s Best Mashed Potatoes')
    assert_equal 'creme-brulee', Recipe.slugify('Crème Brûlée!')
  end
end
