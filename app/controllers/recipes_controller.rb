class RecipesController < ApplicationController
  # before_filter :authenticate_user!, except: [:index, :show]
  skip_before_action :verify_authenticity_token

  def index
    respond_to do |format|
      format.html { render plain: 'public/index.html' }
      format.json do
        @recipes = Recipe.all
        headers['Access-Control-Allow-Origin'] = '*'
      end
    end

  end

  def show
    respond_to do |format|
      format.html { render plain: 'public/index.html' }
      format.json { @recipe = Recipe.find(params[:id]) }
    end
  end

  def import
    recipe = Recipe.create!(BaHarvest.harvest(params[:url]))

    head :created, location: recipe
  end

  def whoami
    render text: current_user.email
  end
end
