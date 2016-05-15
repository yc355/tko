class FightersController < ApplicationController
  def fighter_search
    begin
      result = MMAService.fighter_query(params[:fighter_search_query])
      render json: result, status: result.class == Hash ? 200 : 400
    rescue => error
      render json: error
    end
  end
end
