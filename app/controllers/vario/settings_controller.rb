module Vario
  class SettingsController < ApplicationController
    add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), :settings_path

    def index
      @settings = Setting.all
    end

    def show
      @setting = Setting.find(params[:id])
      add_breadcrumb @setting.name, setting_path(@setting)
    end
  end
end
