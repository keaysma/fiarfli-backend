Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "grid#data"

  get "/api/grid", to: "grid#data"
  get "/api/grid/head", to: "grid#head"
  post "/api/grid", to: "grid#update"
  #get "/grid", to: "grid#page"

  post "/api/mail", to: "mail#create"
  
  get "/api/forger", to: "forger#data"
end
