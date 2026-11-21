require 'base64'
require 'digest'

# A recipe stored as a Base64-encoded JSON file in data/recipes, so recipes live
# in the repository rather than the database. Each file is named by the MD5 of
# its contents (<md5>.b64) so the name doesn't reveal the recipe; the readable
# id used in URLs is stored inside the file.
class Recipe
  include ActiveModel::Model
  include ActiveModel::Attributes

  class DuplicateLink < StandardError; end

  EXTENSION = '.b64'.freeze

  mattr_accessor :directory, default: Rails.root.join('data', 'recipes')

  attribute :id, :string
  attribute :title, :string
  attribute :link, :string
  attribute :thumbnail, :string # the original image URL
  attribute :image, :string # local copy, as an asset path under app/assets/images (see ImageDownload)
  attribute :servings, :string
  attribute :ingredients, default: -> { [] }
  attribute :preparation_steps, default: -> { [] }
  attribute :created_at, :datetime

  # The file this recipe was loaded from or last saved to.
  attr_reader :path

  def self.all
    Dir.glob(File.join(directory, "*#{EXTENSION}")).map { |path| load(path) }.sort_by { |r| [r.created_at || Time.at(0), r.id] }
  end

  def self.find(id)
    all.find { |r| r.id == id.to_s } || raise(ActiveRecord::RecordNotFound, "Couldn't find Recipe with id=#{id}")
  end

  def self.find_by_link(link)
    all.find { |r| r.link == link }
  end

  def self.create!(attrs)
    new(attrs).tap(&:save!)
  end

  def self.load(path)
    new(JSON.parse(Base64.decode64(File.read(path)))).tap { |recipe| recipe.instance_variable_set(:@path, path) }
  end

  def save!
    raise DuplicateLink, "A recipe for #{link} already exists" if link.present? && self.class.find_by_link(link)&.id != id

    self.id ||= unique_id
    self.created_at ||= Time.current
    content = Base64.encode64(JSON.pretty_generate(attributes))
    new_path = File.join(directory, "#{Digest::MD5.hexdigest(content)}#{EXTENSION}")

    FileUtils.mkdir_p(directory)
    File.write(new_path, content)
    File.delete(path) if path && path.to_s != new_path && File.exist?(path)
    @path = new_path
    true
  end

  def persisted?
    path.present? && File.exist?(path)
  end

  def normalized_ingredients
    return ingredients unless ingredients.first.is_a? Hash

    # The older schema deconstructed ingredients a bit more.
    ingredients.map do |i|
      i.stringify_keys
       .slice('quantity', 'unit', 'name')
       .select { |_k, v| v.present? }
       .values
       .join(' ')
    end
  end

  private

  def unique_id
    taken = self.class.all.map(&:id)
    base = title.to_s.parameterize.presence || 'recipe'
    candidate = base
    n = 1
    candidate = "#{base}-#{n += 1}" while taken.include?(candidate)
    candidate
  end
end
