# frozen_string_literal: true

module Vario
  # Saves settings on a page of the host's (render_vario_settings): each the
  # value on exactly the page's context (customer_id: 5), or without one its
  # own value, then back to that page
  class ValuesController < ApplicationController
    def update
      settable = GlobalID::Locator.locate_signed(params[:settable], for: 'Vario')
      context = Vario.verifier.verified(params[:context].to_s)
      raise ActiveRecord::RecordNotFound, 'Unknown settable' unless settable && context

      Setting.transaction do
        params.fetch(:values, {}).to_unsafe_h.each do |name, attributes|
          definition = Topic.definition(settable, name)
          raise UnknownSetting, "Setting '#{name}' is not defined for #{settable.class.name}" unless definition
          raise Pundit::NotAuthorizedError, "may not update #{definition.topic.key}" unless policy(SettableTopic.new(settable: settable, topic: definition.topic)).update?

          setting = settable.public_send(settable.vario_settings_association).find_or_initialize_by(name: name)
          setting.value_on!(context, attributes['value'])
        end
      end

      redirect_back_or_to topics_path(settable: params[:settable]), notice: t('vario.pages.update.saved')
    end
  end
end
