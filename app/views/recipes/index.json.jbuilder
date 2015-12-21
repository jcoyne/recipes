json.recipes do
  json.array! @recipes, partial: 'recipe', as: :recipe
end
