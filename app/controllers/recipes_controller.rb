class RecipesController < ApplicationController
  # before_filter :authenticate_user!, except: [:index, :show]
  skip_before_action :verify_authenticity_token

  def index
    @recipes = Recipe.all
    headers['Access-Control-Allow-Origin'] = '*'
  end

  def show
    @recipe = Recipe.find(prams[:id])
  end

  def import
    recipe = Recipe.create!(BaHarvest.harvest(params[:url]))

    head :created, location: recipe
  end

  def whoami
    render text: current_user.email
  end
end
