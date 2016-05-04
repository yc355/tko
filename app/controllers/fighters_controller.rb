class FightersController < ApplicationController
  def fighter_search
    begin
      result = MMA.fighter_query(params[:fighter_search_query])
      render json: result, status: result.class == Hash ? 200 : 400
    rescue
      redirect_to '/'
    end
  end
end
