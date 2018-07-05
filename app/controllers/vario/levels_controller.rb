module Vario
  class LevelsController < ApplicationController
    def new
      @setting = Setting.find(params[:setting_id])
      @level = Level.new(@setting, {})
    end

    def create
      @setting = Setting.find(params[:setting_id])
      @level = Level.new(@setting, level_params)
      @setting.update_level(nil, params[:conditions], params[:value])

      render json: @setting.levels
    end

    def update
      @setting = Setting.find(params[:setting_id])
      @level = @setting.levels.find { |level| level.id == params[:id] }
      @setting.update_level(params[:id], params[:conditions], params[:value])

      render json: @setting.levels
    end

    def move_up
      @setting = Setting.find(params[:setting_id])
      @level = @setting.levels.find { |level| level.id == params[:id] }
      @level.move_up

      redirect_to setting_path(@setting)
    end

    def move_down
      @setting = Setting.find(params[:setting_id])
      @level = @setting.levels.find { |level| level.id == params[:id] }
      @level.move_down

      redirect_to setting_path(@setting)
    end

    private

    def level_params
      params.require(:level)
    end
  end
end
