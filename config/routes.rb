Rails.application.routes.draw do
  #devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#index'

  get "/admin", :to => "admin#index", :as => "admin"

  namespace :admin do
    resources :users
  end

  Rails.application.routes.draw do
    devise_for :users, controllers: {
      registrations: 'users/registrations'
    }
  end

  get '/ns/*id', :to => "terms#show", :as => "term"
  patch 'terms/*id/deprecate_only', :to => "terms#deprecate_only", :as => "deprecate_only_term"
  patch 'terms/*id', :to => "terms#update", :as => "update_term"
  patch 'vocabularies/*id/deprecate_only', :to => "vocabularies#deprecate_only", :as => "deprecate_only_vocabulary"
  patch 'vocabularies/*id', :to => "vocabularies#update", :as => "update_vocabulary"
  patch 'predicates/*id', :to => "predicates#update", :as => "update_predicate"

  resources :vocabularies, :only => [:index, :new, :create, :edit]
  get '/vocabularies/*vocabulary_id/new', :to => "terms#new", :as => "new_term"
  resources :predicates, :only => [:index, :new, :create, :edit]
  post '/vocabularies/*vocabulary_id', :to => "terms#create", :as => "create_term"
  get 'terms/*id/edit', :to => "terms#edit", :as => "edit_term"
  get 'terms/*id/deprecate', :to => "terms#deprecate", :as => "deprecate_term"
  get 'vocabularies/*id/deprecate', :to => "vocabularies#deprecate", :as => "deprecate_vocabulary"


  get "/import_rdf", :to => "import_rdf#index", :as => "import_rdf_form"
  post "/import_rdf", :to => "import_rdf#import", :as => "import_rdf"
  get "/load_rdf", :to => "import_rdf#load", :as => "load_rdf_form"
  post "/load_rdf", :to => "import_rdf#save", :as => "save_rdf"
end
