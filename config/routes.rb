Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'pages#home'

  get 'home_search', to: 'pages#home_search'

  resources :work_orders, only: [:show], param: :ref do
    post :search, on: :collection
  end

  namespace :api do
    resources :properties, only: [], param: :ref do
      member do
        get :repairs_history
      end
    end

    resources :work_orders, only: [], param: :ref do
      member do
        get :description
        get :documents
        get :notes_and_appointments
        get :possibly_related_work_orders
        get :related_work_orders
        post :notes
      end
    end
  end
end
