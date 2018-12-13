require_dependency 'vario/application_controller'

module Vario
  class LevelsController < ApplicationController

    before_action :set_objects

    def new
      @level = Level.new(@setting, {}, true)
      add_breadcrumb I18n.t('breadcrumbs.vario.levels.new')
    end

    def create
      @level = Level.new(@setting, level_params)
      @setting.levels.unshift @level


      if @setting.save
        redirect_to setting_path(@setting)
      else
        render :new
      end
    end

    def edit
      @level = @setting.levels.find { |level| level.id == params[:id] }
    end

    def update
      @level = @setting.levels.find { |level| level.id == params[:id] }
      @level.value = level_params[:value]
      @level.conditions = level_params[:conditions].to_h

      if @setting.save
        redirect_to setting_path(@setting)
      else
        render :new
      end
    end

    def destroy
      @setting.levels.reject! { |level| level.id == params[:id] }
      @setting.save!

      redirect_to setting_path(@setting)
    end

    def move_up
      @level = @setting.levels.find { |level| level.id == params[:id] }
      @level.move_up

      redirect_to setting_path(@setting)
    end

    def move_down
      @level = @setting.levels.find { |level| level.id == params[:id] }
      @level.move_down

      redirect_to setting_path(@setting)
    end

    private

    def set_objects
      @setting = Setting.find(params[:setting_id])
      add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), breadcrumb_settings_path(@setting)
      add_breadcrumb @setting.name, setting_path(@setting)
    end

    def level_params
      params.require(:level).permit(:value, value: [], conditions: {})
    end
  end
end
