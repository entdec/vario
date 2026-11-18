require_dependency 'vario/application_controller'

module Vario
  class LevelsController < ApplicationController
    before_action :set_objects

    def create
      @level = Level.new(@setting, level_params)
      @setting.levels.unshift @level
      @level.conditions = normalize_booleans(level_params[:conditions].to_h)
      @level.conditions = normalize_booleans(level_params[:conditions].to_h)
      if @setting.save
        redirect_back_or_to_setting
      else
        redirect_to setting_path(@setting), alert: @setting.errors.full_messages.join(',')
      end
    end

    def update
      if params[:commit] == 'delete'
        self.action_name = 'destroy'
        return destroy
      end

      @level = @setting.levels.find { |level| level.id == params[:id] }
      @level.value = level_params[:value]
      @level.conditions = normalize_booleans(level_params[:conditions].to_h)
      if @setting.save
        redirect_back_or_to_setting
      else
        redirect_to setting_path(@setting), alert: @setting.errors.full_messages.join(',')
      end
    end

    def destroy
      @setting.levels.reject! { |level| level.id == params[:id] }
      @setting.save
      redirect_back_or_to_setting
    end

    def move
      oldIndex = @setting.levels.find_index { |level| level.id == params[:id] }
      newIndex = params[:index]
      @level = @setting.levels[oldIndex]
      @level.move(oldIndex - newIndex)

      render json: { old: oldIndex, new: newIndex }
    end

    def index; end
    
    def show; end

    private

    # Back to the page the level was changed on, a host's page with
    # render_vario_settings, else the setting's
    def redirect_back_or_to_setting
      if request.referer.present? && URI.parse(request.referer).path != setting_path(@setting)
        redirect_to request.referer
      else
        redirect_to setting_path(@setting)
      end
    end

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

    def normalize_booleans(conditions)
      boolean_keys = Vario.config.keys.select {|k,v|v[:type] == :boolean}.keys
      boolean_keys.each do |k|
        conditions[k.to_sym] = conditions[k] == "1" ? true : false
      end
      conditions
    end
  end
end
