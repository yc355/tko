class FightersController < ApplicationController
  def fighter_search
    begin
      result = MMAService.fighter_search(params[:fighter_search_query])
      render json: result
    rescue => error
      render json: error
    end
  end
end
