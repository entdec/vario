# frozen_string_literal: true

module Vario
  # A settable's topics (Vario::Topic), and a topic's settings on a page,
  # saved as a whole: their own values and refinements
  class TopicsController < ApplicationController
    before_action :set_settable
    before_action :set_topic, only: %i[show update variables records]
    before_action :set_definition, only: %i[variables records]

    def index
      topic = @topics.first
      return redirect_to topic_path(topic.key, settable: params[:settable]) if topic

      render :index
    end

    # With applies[<root>]: what every setting is in that context, and why
    def show
      @settings = settings_by_key
      @applies = applies_context if params[:applies]
    end

    def update
      raise Pundit::NotAuthorizedError, "may not update #{@topic.key}" unless policy(@topic).update?

      @settings = settings_by_key
      settings_params.each do |key, attributes|
        @settings[key]&.assign_attributes(attributes)
      end

      if save(@settings.values)
        redirect_to topic_path(@topic.key, settable: params[:settable]), notice: t('vario.pages.update.saved')
      else
        flash.now[:alert] = t('vario.pages.update.not_saved')
        render :show, status: :unprocessable_content
      end
    end

    # GET variables?setting=<key>&path=order: as Liquidum's (variables_url)
    def variables
      render json: { path: params[:path].to_s, variables: ContextVariables.new(@definition.context).at(params[:path]) }
    end

    # GET records?setting=<key>&path=location: an object variable's records
    # (records_url)
    def records
      model = ContextVariables.new(@definition.context).model(params[:path])
      return head(:not_found) unless model

      render json: { records: Topic.records_of(model, @settable).map { |record| { label: Topic.label_of(record), value: record.id.to_s } } }
    end

    private

    # The context chosen in "What applies?": for an object root its record
    # (in its drop, for a drop root), else the value as given
    def applies_context
      given = params.require(:applies).permit(*@topic.topic.context.keys).to_h.compact_blank
      given.to_h do |root, value|
        type = @topic.topic.context[root]
        model = ContextVariables.new(@topic.topic.context).model(root)
        record = model&.find_by(model.primary_key => value)
        [root, type.is_a?(Class) && type < Liquid::Drop && record ? type.new(record) : record || value]
      end
    end

    def set_definition
      @definition = @topic.topic.definitions.values.find { |definition| definition.key == params[:setting] }
      raise ActiveRecord::RecordNotFound, "Unknown setting #{params[:setting]}" unless @definition
    end

    def set_settable
      @settable = GlobalID::Locator.locate_signed(params[:settable], for: 'Vario')
      raise ActiveRecord::RecordNotFound, 'Unknown settable' unless @settable

      @topics = Topic.for(@settable).map { |topic| SettableTopic.new(settable: @settable, topic: topic) }.select { |topic| policy(topic).show? }
    end

    def set_topic
      @topic = @topics.find { |topic| topic.key == params[:key] }
      raise ActiveRecord::RecordNotFound, "Unknown topic #{params[:key]}" unless @topic
    end

    # Its settings' rows by key, new ones for those without
    def settings_by_key
      rows = @settable.public_send(@settable.vario_settings_association).includes(:refinements).where(name: @topic.topic.definitions.keys).index_by(&:name)
      @topic.topic.definitions.values.to_h do |definition|
        [definition.key, rows[definition.name] || @settable.public_send(@settable.vario_settings_association).build(name: definition.name)]
      end
    end

    # Those changed, or new with a value or refinements, in one go
    def save(settings)
      settings = settings.select { |setting| setting.persisted? ? setting.changed_for_autosave? : (!setting.value.nil? || setting.refinements.any?) }
      return false unless settings.map(&:valid?).all?

      Setting.transaction { settings.each(&:save!) }
      true
    end

    # settings[<key>][value], settings[<key>][refinements_attributes][<n>][...]
    def settings_params
      keys = @topic.topic.definitions.values.map(&:key)
      settings = params.fetch(:settings, {})
      keys.select { |key| settings.key?(key) }.to_h do |key|
        [key, setting_params(settings.require(key))]
      end
    end

    # A value is a setting's type (a list, a text, …), so as sent
    def setting_params(setting)
      setting = setting.to_unsafe_h
      attributes = setting.slice('value')
      return attributes unless setting['refinements_attributes']

      attributes.merge('refinements_attributes' => setting['refinements_attributes'].values.map do |refinement|
        attributes = refinement.slice('id', 'position', 'enabled', 'note', '_destroy', 'value')
        refinement.key?('conditions') ? attributes.merge('conditions' => conditions(refinement['conditions'])) : attributes
      end)
    end

    # As the conditions component sends them: match, rules by index
    def conditions(conditions)
      conditions = conditions.to_h
      rules = conditions['rules'].to_h.values.map { |rule| rule.to_h.slice('variable', 'operator', 'value', 'value_to') }
      { 'match' => conditions['match'].presence || 'all', 'rules' => rules.reject { |rule| rule['variable'].blank? } }
    end
  end
end
