require_dependency 'vario/application_controller'

module Vario
  class SettingsController < ApplicationController
    include Satis::Forms::Concerns::Options
    include Pagy::Backend

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
      @groups = @groups.find_all { |g| Vario.config.show_group?(g) }
      @groups = @groups.each_with_object(Hash.new(0)) { |v, h| h[v] += 1; }.map { |k, v| { name: k, settings: v } }
    end

    def show
      @setting = Setting.find(params[:id])

      if respond_to?(:add_breadcrumb)
        add_breadcrumb I18n.t('breadcrumbs.vario.settings.index'), breadcrumb_settings_path(@setting)
        add_breadcrumb @setting.name, setting_path(@setting)
      end
    end

    def levels
      @setting = Setting.find(params[:id])
      render :levels, layout: false
    end

    def filter_collection
      @setting = Setting.find(params[:id])
      @setting = Condition.new(@setting, params[:condition_key], params[:condition_value])

      @filter_items = true

      if @setting.collection.is_a?(Proc)
        if @setting.collection.parameters.size == 1
          @filter_items = false
          @items = @setting.collection.call(params[:term])
        else
          @items = @setting.collection.call
        end
      else
        @items = @setting.collection
      end

      if @filter_items && @items.is_a?(Array)
        @items = @items.select do |item|
          item.is_a?(Array) ? item[0].match?(/#{params[:term]}/i) || item[1].match?(/#{params[:term]}/i) : item.match?(/#{params[:term]}/i)
        end
      end

      @pagy, @items = @items.is_a?(Array) ? pagy_array(@items) : pagy(@items)
      @value_method, @text_method = value_text_methods(@items)

      render layout: false
    end
  end
end
