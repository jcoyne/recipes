json.(recipe, :id, :title, :link, :thumbnail, :servings, :preparation_steps)
json.image_url(recipe.image.present? ? image_path(recipe.image) : nil)
json.ingredients recipe.normalized_ingredients
