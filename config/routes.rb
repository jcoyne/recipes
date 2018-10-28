Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "sessions" }
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  resources :recipes, only: [:index, :show] do
    collection do
      post :import
      get :whoami
    end
  end
end
