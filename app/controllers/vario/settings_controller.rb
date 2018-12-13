require_dependency 'vario/application_controller'

module Vario
  class SettingsController < ApplicationController

    def index
      add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), settings_path(settable: params[:settable])
      add_breadcrumb params[:group], settings_path(settable: params[:settable], group: params[:group]) if params[:group]
      @settable = GlobalID::Locator.locate_signed(params[:settable], for: 'Vario')
      Vario.config.pre_create_settings(@settable)

      @settings = Setting.where(settable: @settable).order(:name).includes(:settable)
      if params[:group]
        @settings = @settings.where("name ILIKE ?", params[:group] + '%')
      else
        @groups = @settings.map(&:name).select { |setting| setting =~ /\./ }.map { |setting| setting.split('.').first }
        @groups = @groups.reduce(Hash.new(0)) {|h,v| h[v] += 1 ; h }.map{ |k,v| { name: k, settings: v } }
        @settings = @settings.reject { |setting| setting.name =~ /\./ }
      end
      @settings = @settings.select(&:initialized?)
    end

    def show
      @setting = Setting.find(params[:id])
      add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), breadcrumb_settings_path(@setting)
      group = @setting.name.split('.').first if @setting.name =~ /\./
      add_breadcrumb group, breadcrumb_settings_path(@setting, group: group) if group
      add_breadcrumb @setting.name, setting_path(@setting)
    end
  end
end
