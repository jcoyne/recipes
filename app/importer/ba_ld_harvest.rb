# Imports the LD+JSON from BA
class BaLdHarvest < Harvest
  def self.parse(html, uri_str)
    ld_node = html.css('script[type="application/ld+json"]')
    json = JSON.parse(ld_node.text)
    {
      title: json['name'],
      link: uri_str,
      thumbnail: json['image'],
      servings: json['recipeYield'],
      ingredients: json['recipeIngredient'],
      preparation_steps: steps(json['recipeInstructions'])
    }.tap { |x| puts x }
  end


  def self.steps(instructions)
    if instructions.respond_to?(:map)
      # Bon Appetit uses this
      return instructions.map { |how_to_step| how_to_step['text'] }
    end
    # Delish uses this:
    instructions
  end
end
