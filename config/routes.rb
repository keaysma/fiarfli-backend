Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "grid#data"

  get "/api/grid", to: "grid#data"
  post "/api/grid", to: "grid#update"
  #get "/grid", to: "grid#page"

  post "/api/mail", to: "mail#create"
end
