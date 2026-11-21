require 'base64'
require 'digest'
require 'fileutils'
require 'json'
require 'time'

# A recipe stored as a Base64-encoded JSON file in site/recipes. Each file is
# named by the MD5 of its contents (<md5>.b64) so the name doesn't reveal the
# recipe; the readable id used in URLs is stored inside the file. Because a
# static host can't list a directory, site/recipes/index.json lists the files
# (oldest first) for the front end to load.
class Recipe
  class DuplicateLink < StandardError; end
  class NotFound < StandardError; end

  ATTRIBUTES = %w[id title link thumbnail image servings ingredients preparation_steps created_at].freeze
  EXTENSION = '.b64'.freeze
  INDEX = 'index.json'.freeze

  class << self
    attr_writer :directory

    def directory
      @directory ||= File.expand_path('../site/recipes', __dir__)
    end

    def all
      Dir.glob(File.join(directory, "*#{EXTENSION}")).map { |path| load(path) }.sort_by { |r| [r.created_time, r.id.to_s] }
    end

    def find(id)
      all.find { |r| r.id == id.to_s } || raise(NotFound, "Couldn't find Recipe with id=#{id}")
    end

    def find_by_link(link)
      all.find { |r| r.link == link }
    end

    def create!(attrs)
      new(attrs).tap(&:save!)
    end

    def load(path)
      new(JSON.parse(Base64.decode64(File.read(path)))).tap { |recipe| recipe.instance_variable_set(:@path, path) }
    end

    # Rewrite index.json from the recipe files on disk.
    def write_index
      File.write(File.join(directory, INDEX), "#{JSON.pretty_generate(all.map { |r| File.basename(r.path) })}\n")
    end
  end

  # thumbnail is the original image URL; image is the local copy, relative to site/ (see ImageDownload).
  attr_accessor(*ATTRIBUTES)

  # The file this recipe was loaded from or last saved to.
  attr_reader :path

  def initialize(attrs = {})
    attrs.each { |name, value| public_send("#{name}=", value) if ATTRIBUTES.include?(name.to_s) }
    @ingredients ||= []
    @preparation_steps ||= []
  end

  def attributes
    ATTRIBUTES.to_h { |name| [name, public_send(name)] }
  end

  def save!
    raise DuplicateLink, "A recipe for #{link} already exists" if link && self.class.find_by_link(link)&.id != id

    self.id ||= unique_id
    self.created_at ||= Time.now.utc.to_s
    content = Base64.encode64(JSON.pretty_generate(attributes))
    new_path = File.join(self.class.directory, "#{Digest::MD5.hexdigest(content)}#{EXTENSION}")

    FileUtils.mkdir_p(self.class.directory)
    File.write(new_path, content)
    File.delete(path) if path && path != new_path && File.exist?(path)
    @path = new_path
    self.class.write_index
    true
  end

  def persisted?
    !path.nil? && File.exist?(path)
  end

  def created_time
    Time.parse(created_at.to_s)
  rescue ArgumentError
    Time.at(0)
  end

  # "BA’s Best Mashed Potatoes" => "ba-s-best-mashed-potatoes"
  def self.slugify(text)
    text.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '').downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
  end

  private

  def unique_id
    taken = self.class.all.map(&:id)
    base = self.class.slugify(title)
    base = 'recipe' if base.empty?
    candidate = base
    n = 1
    candidate = "#{base}-#{n += 1}" while taken.include?(candidate)
    candidate
  end
end
