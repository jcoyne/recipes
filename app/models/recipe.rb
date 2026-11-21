require 'base64'

# A recipe stored as a Base64-encoded JSON file in data/recipes/<id>.b64,
# so recipes live in the repository rather than the database.
class Recipe
  include ActiveModel::Model
  include ActiveModel::Attributes

  class DuplicateLink < StandardError; end

  ID_FORMAT = /\A[a-z0-9][a-z0-9-]*\z/
  EXTENSION = '.b64'.freeze

  mattr_accessor :directory, default: Rails.root.join('data', 'recipes')

  attribute :id, :string
  attribute :title, :string
  attribute :link, :string
  attribute :thumbnail, :string
  attribute :servings, :string
  attribute :ingredients, default: -> { [] }
  attribute :preparation_steps, default: -> { [] }
  attribute :created_at, :datetime

  def self.all
    Dir.glob(File.join(directory, "*#{EXTENSION}")).map { |path| load(path) }.sort_by { |r| [r.created_at || Time.at(0), r.id] }
  end

  def self.find(id)
    path = path_for(id) if id.to_s.match?(ID_FORMAT)
    raise ActiveRecord::RecordNotFound, "Couldn't find Recipe with id=#{id}" unless path && File.exist?(path)

    load(path)
  end

  def self.find_by_link(link)
    all.find { |r| r.link == link }
  end

  def self.create!(attrs)
    new(attrs).tap(&:save!)
  end

  def self.load(path)
    new(JSON.parse(Base64.decode64(File.read(path))).merge('id' => File.basename(path, EXTENSION)))
  end

  def self.path_for(id)
    File.join(directory, "#{id}#{EXTENSION}")
  end

  def save!
    raise DuplicateLink, "A recipe for #{link} already exists" if link.present? && self.class.find_by_link(link)&.id != id

    self.id ||= unique_id
    self.created_at ||= Time.current
    FileUtils.mkdir_p(directory)
    File.write(self.class.path_for(id), Base64.encode64(JSON.pretty_generate(attributes.except('id'))))
    true
  end

  def persisted?
    id.present? && File.exist?(self.class.path_for(id))
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
    base = title.to_s.parameterize.presence || 'recipe'
    candidate = base
    n = 1
    candidate = "#{base}-#{n += 1}" while File.exist?(self.class.path_for(candidate))
    candidate
  end
end
