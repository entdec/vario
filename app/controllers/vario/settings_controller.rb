require_dependency 'vario/application_controller'

module Vario
  class SettingsController < ApplicationController

    def index
      if respond_to?(:add_breadcrumb)
        add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), settings_path(settable: params[:settable])
      end

      @settable = GlobalID::Locator.locate_signed(params[:settable], for: 'Vario')
      @title = 'Settings'
      @title = "#{@title} for #{@settable.class.name} #{@settable.name}" if @settable.respond_to?(:name)
      Vario.config.pre_create_settings(@settable)

      @settings = Setting.where(settable: @settable).order(:name).includes(:settable)
      @groups = @settings.map(&:name).select { |setting| setting =~ /\./ }.map { |setting| setting.split('.').first }
      @groups = @groups.reduce(Hash.new(0)) {|h,v| h[v] += 1 ; h }.map{ |k,v| { name: k, settings: v } }
    end

    def show
      @setting = Setting.find(params[:id])

      if respond_to?(:add_breadcrumb)
        add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), breadcrumb_settings_path(@setting)
        add_breadcrumb @setting.name, setting_path(@setting)
      end
    end
  end
end
