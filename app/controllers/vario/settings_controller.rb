require_dependency 'vario/application_controller'

module Vario
  class SettingsController < ApplicationController

    def index
      add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), settings_path(settable: params[:settable])
      settable = GlobalID::Locator.locate_signed(params[:settable], for: 'Scribo')

      Vario.config.pre_create_settings(settable)
      @settings = Setting.all.where(settable: settable).order(:name)
      @settings = @settings.select(&:initialized?)
    end

    def show
      @setting = Setting.find(params[:id])
      add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), breadcrumb_settings_path(@setting)
      add_breadcrumb @setting.name, setting_path(@setting)
    end
  end
end
