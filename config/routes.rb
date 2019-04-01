Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'pages#home'

  get 'home_search', to: 'pages#home_search'

  resources :work_orders, only: [:show], param: :ref do
    post :search, on: :collection
  end

end
