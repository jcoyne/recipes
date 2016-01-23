class EcHarvest < Harvest
  def self.parse(html, uri_str)
    recipe = html
    title = recipe.at_css('h1[itemprop="name"]').text.strip
    ingredients = recipe.css('[itemprop="ingredients"]')
    ingredient_list = ingredients.map do |ingredient|
      {
        #quantity: ingredient.at_css('.quantity').text,
        #unit: ingredient.at_css('.unit').text,
        name: ingredient.text }
    end

    # itemprop="recipeInstructions"
    preparation = recipe.css('.instructions .preparation-step').map { |n| n.text.strip }
    thumbnail = html.at_css('meta[property="og:image"]').attribute('content').text
    servings = recipe.at_css('recipeYield').try(:text)

    { title: title, link: uri_str, thumbnail: thumbnail, servings: servings,
               ingredients: ingredient_list, preparation_steps: preparation }
  end
end

