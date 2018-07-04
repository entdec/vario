module Vario
  class LevelsController < ApplicationController
    def new
      @setting = Setting.find(params[:setting_id])
      @level = Level.new(@setting, {})
    end

    def create
      @setting = Setting.find(params[:setting_id])
      @setting.update_level(nil, params[:position], params[:conditions], params[:value])
      render json: @setting.levels
    end

    def update
      @setting = Setting.find(params[:setting_id])
      @setting.update_level(params[:id], params[:position], params[:conditions], params[:value])
      render json: @setting.levels
    end
  end
end
