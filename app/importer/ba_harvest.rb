require 'open-uri'

module BaHarvest

  def self.harvest(uri_str)
    doc = begin
            open(uri_str)
          rescue Errno::ENOENT
            $stderr.puts "Unable to open #{uri_str}"
            exit
          end

    html = Nokogiri::HTML(doc)

    recipe = html.at_css('#recipe-ingredients')

    # TODO get the JSON-ld:
    #    <script type="application/ld+json">
       # {"@context":"http:\/\/schema.org","@type":"NewsArticle","headline":"Pepperoni Panzanella","url":"http:\/\/www.example.com\/recipe\/pepperoni-panzanella","thumbnailUrl":"http:\/\/www.example.com\/wp-content\/uploads\/2015\/06\/SCHOOL-LUNCHES-6-of-12-150x150.jpg","articleId":"1748004","dateCreated":"2015-06-16T17:56:16Z","articleSection":"Recipes","creator":["Jim Barfoo"],"keywords":["basil","bread","camp lunch","lunch","mozzarella","panzanella","pepperoni","salad","web recipe","post_type: recipe"]}   </script>


    title = recipe.at_css('.recipe-title').text
    ingredients = recipe.css('.ingredient-sets ul.ingredients li')
    # itemprop="ingredients"
    ingredient_list = ingredients.map do |ingredient|
      { quantity: ingredient.at_css('.quantity').text,
        unit: ingredient.at_css('.unit').text,
        name: ingredient.at_css('.name').text }
    end

    # itemprop="recipeInstructions"
    preparation = recipe.css('.preparation .prep-steps .step').map { |n| n.text.strip }
    thumbnail = html.at_css('meta[property="og:image"]').attribute('content').text

    servings = recipe.at_css('.total-servings').try(:text)

    { title: title, link: uri_str, thumbnail: thumbnail, servings: servings,
               ingredients: ingredient_list, preparation_steps: preparation }
  end
end
