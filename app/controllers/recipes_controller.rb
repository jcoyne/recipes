class RecipesController < ApplicationController
  def index
    @recipes = Recipe.all
    headers['Access-Control-Allow-Origin'] = '*'
  end
end
