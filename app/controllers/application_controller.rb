class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  def bad_route
    render json: "Don't be scared homie."
  end
end
