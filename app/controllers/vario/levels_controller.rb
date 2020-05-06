require_dependency 'vario/application_controller'

module Vario
  class LevelsController < ApplicationController
    before_action :set_objects

    def create
      @level = Level.new(@setting, level_params)
      @setting.levels.unshift @level
      @setting.save!

      respond_to do |format|
        format.html { redirect_to setting_path(@setting) }
        format.js
      end
    end

    def update
      return destroy if params[:commit] == 'delete'

      @level = @setting.levels.find { |level| level.id == params[:id] }
      @level.value = level_params[:value]
      @level.conditions = level_params[:conditions].to_h
      @setting.save!

      respond_to do |format|
        format.html { redirect_to setting_path(@setting) }
        format.js
      end
    end

    def destroy
      @setting.levels.reject! { |level| level.id == params[:id] }
      @setting.save!

      respond_to do |format|
        format.html { redirect_to setting_path(@setting) }
        format.js { render :update }
      end
    end

    def move
      oldIndex = @setting.levels.find_index { |level| level.id == params[:id] }
      newIndex = params[:index]
      @level = @setting.levels[oldIndex]
      @level.move(oldIndex - newIndex)

      render json: { old: oldIndex, new: newIndex }
    end

    private

    def set_objects
      @setting = Setting.find(params[:setting_id])
      if respond_to? :add_breadcrumb
        add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), breadcrumb_settings_path(@setting)
        add_breadcrumb @setting.name, setting_path(@setting)
      end
    end

    def level_params
      params.require(:level).permit(:value, value: [], conditions: {})
    end
  end
end
