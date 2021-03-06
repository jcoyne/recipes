class RecipesController < ApplicationController
  # before_filter :authenticate_user!, except: [:index, :show]
  skip_before_action :verify_authenticity_token

  def index
    respond_to do |format|
      format.json do
        @recipes = Recipe.all
        headers['Access-Control-Allow-Origin'] = '*'
      end
      format.html { render file: 'public/index.html', layout: false }
    end

  end

  def show
    respond_to do |format|
      format.json { @recipe = Recipe.find(params[:id]) }
      format.html { render file: 'public/index.html', layout: false }
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
