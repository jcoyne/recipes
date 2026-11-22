require_relative 'harvest'

# Imports a schema.org Recipe from a page's JSON-LD (Bon Appétit, NYT Cooking, and
# most other recipe sites publish one).
class LdHarvest < Harvest
  def self.parse(html, uri_str)
    recipe = find_recipe(html) or raise ArgumentError, "No JSON-LD Recipe found at #{uri_str}"

    {
      title: text(recipe['name']),
      link: uri_str,
      thumbnail: image_url(recipe['image']),
      servings: servings(recipe['recipeYield']),
      ingredients: Array(recipe['recipeIngredient']).map { |ingredient| text(ingredient) }.reject(&:empty?),
      preparation_steps: steps(recipe['recipeInstructions'])
    }
  end

  # Pages can have several JSON-LD blocks (WebPage, Organization, ...), and a block can
  # hold a list of nodes or an @graph; use the first node typed Recipe.
  def self.find_recipe(html)
    html.css('script[type="application/ld+json"]').each do |script|
      data = begin
               JSON.parse(script.text)
             rescue JSON::ParserError
               next
             end
      recipe = nodes(data).find { |node| Array(node['@type']).include?('Recipe') }
      return recipe if recipe
    end
    nil
  end

  def self.nodes(data)
    case data
    when Array then data.flat_map { |item| nodes(item) }
    when Hash then [data, *nodes(data['@graph'])]
    else []
    end
  end

  # image may be a URL, an ImageObject, or a list of either. Take the widest; when no
  # widths are given (a list of URLs), take the first.
  def self.image_url(image)
    image_candidates(image).max_by { |_url, width| width }&.first
  end

  def self.image_candidates(image)
    case image
    when String then [[image, 0]]
    when Hash
      url = image['contentUrl'] || image['url']
      url ? [[url, image['width'].to_i]] : []
    when Array then image.flat_map { |item| image_candidates(item) }
    else []
    end
  end

  # recipeYield may be "4 servings" or a list like ["4", "4 servings"]; keep the most descriptive.
  def self.servings(recipe_yield)
    Array(recipe_yield).map { |value| text(value) }.max_by(&:length)
  end

  # recipeInstructions may be text, HowToSteps, or HowToSections of HowToSteps.
  def self.steps(instructions)
    case instructions
    when String then instructions.split(/\n+/).map { |line| text(line) }.reject(&:empty?)
    when Array then instructions.flat_map { |item| steps(item) }
    when Hash
      if instructions['itemListElement']
        steps(instructions['itemListElement'])
      else
        [text(instructions['text'] || instructions['name'])].reject(&:empty?)
      end
    else []
    end
  end

  # Some sites put HTML tags or entities in JSON-LD text; reduce it to plain text, keeping
  # line breaks (e.g. a "Do Ahead:" note after a step) but tidying spaces within each line.
  def self.text(value)
    Nokogiri::HTML5.fragment(value.to_s).text.split("\n").map { |line| line.gsub(/[[:space:]]+/, ' ').strip }.reject(&:empty?).join("\n")
  end
end
