require_dependency 'vario/application_controller'

module Vario
  class LevelsController < ApplicationController
    self.responder = Auxilium::Responder
    respond_to :html, :js

    before_action :set_objects

    def create
      @level = Level.new(@setting, level_params)
      @setting.levels.unshift @level
      @setting.save

      respond_with @setting, collection_location: setting_path(@setting)
    end

    def update
      if params[:commit] == 'delete'
        self.action_name = 'destroy'
        return destroy
      end

      @level = @setting.levels.find { |level| level.id == params[:id] }
      @level.value = level_params[:value]
      @level.conditions = level_params[:conditions].to_h
      @setting.save

      respond_with @setting, collection_location: setting_path(@setting)
    end

    def destroy
      @setting.levels.reject! { |level| level.id == params[:id] }
      @setting.save

      respond_with @setting, collection_location: setting_path(@setting)
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
      @context = params.dig(:level, :context) || {}
      @setting = Setting.find(params[:setting_id])
      if respond_to? :add_breadcrumb
        add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), breadcrumb_settings_path(@setting)
        add_breadcrumb @setting.name, setting_path(@setting)
      end
    end

    def level_params
      params.require(:level).permit(:value, value: [], conditions: {}, context: {})
    end
  end
end
