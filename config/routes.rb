Rails.application.routes.draw do
  get '/fighter_search/:fighter_search_query', to: 'fighters#fighter_search'

  root 'application#bad_route'
  match '*path' => 'application#bad_route', via: :all
end
