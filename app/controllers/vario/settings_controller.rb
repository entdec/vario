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
      @setting = Setting.find(params[:setting_id])
      @settable = GlobalID::Locator.locate_signed(params[:settable], for: 'Vario')
      @setting.settable = @settable


      if params[:condition_key].present?
        target = Condition.new(@setting, params[:condition_key], params[:condition_value])
        @value_method, @text_method = target.key_data[:value_text_methods]&.call
      else
        target = @setting
        @value_method, @text_method =  target.settable_setting[:value_text_methods]&.call
      end

      @filter_items = true

      if target.collection.is_a?(Proc)
        if target.collection.parameters.size == 1
            @filter_items = false
            @items = target.instance_exec(params[:term], &target.collection)
          else
            @items = target.instance_exec(&target.collection)
        end

        if params[:id].present? && @items.is_a?(ActiveRecord::Relation)
          @items = @items.where(id: params[:id])
        end
      else
        @items = target.collection
      end

      if @filter_items && @items.is_a?(Array)
        @items = @items.select do |item|
          item.is_a?(Array) ? item[0].match?(/#{params[:term]}/i) || item[1].match?(/#{params[:term]}/i) : item.match?(/#{params[:term]}/i)
        end
      end

      if @items.is_a?(Array) || @items.is_a?(ActiveRecord::Relation)
        @pagy, @items = @items.is_a?(Array) ? pagy_array(@items) : pagy(@items)
      else
        @items = []
      end

      @value_method, @text_method = value_text_methods(@items) if @value_method.blank? && @text_method.blank?

      render layout: false
    end

  end
end
