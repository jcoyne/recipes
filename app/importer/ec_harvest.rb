class EcHarvest < Harvest
  def self.parse(html, uri_str)
    recipe = html

    # TODO get the JSON-ld:
    #    <script type="application/ld+json">
       # {"@context":"http:\/\/schema.org","@type":"NewsArticle","headline":"Pepperoni Panzanella","url":"http:\/\/www.example.com\/recipe\/pepperoni-panzanella","thumbnailUrl":"http:\/\/www.example.com\/wp-content\/uploads\/2015\/06\/SCHOOL-LUNCHES-6-of-12-150x150.jpg","articleId":"1748004","dateCreated":"2015-06-16T17:56:16Z","articleSection":"Recipes","creator":["Jim Barfoo"],"keywords":["basil","bread","camp lunch","lunch","mozzarella","panzanella","pepperoni","salad","web recipe","post_type: recipe"]}   </script>


    title = recipe.at_css('[itemprop="name"]').text
    ingredients = recipe.css('[itemprop="ingredients"]')
    # itemprop="ingredients"
    ingredient_list = ingredients.map do |ingredient|
      {
        #quantity: ingredient.at_css('.quantity').text,
        #unit: ingredient.at_css('.unit').text,
        name: ingredient.text }
    end

    # itemprop="recipeInstructions"
    preparation = recipe.css('.instructions .preparation-step').map { |n| n.text.strip }
    thumbnail = nil;
    # thumbnail = html.at_css('meta[property="og:image"]').attribute('content').text
    #
    # servings = recipe.at_css('.total-servings').try(:text)
    servings = nil

    { title: title, link: uri_str, thumbnail: thumbnail, servings: servings,
               ingredients: ingredient_list, preparation_steps: preparation }
  end
end

