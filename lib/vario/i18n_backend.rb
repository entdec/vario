module Vario
  class I18nBackend < I18n::Backend::Simple
    def translate(locale, key, options = {})
      scribo_value = Vario.config.translation_settable&.setting(key, default: super)
      return unless scribo_value.present?
      raise I18n::MissingTranslationData.new(locale, key, options) unless scribo_value.present?

      options.each do |key, value|
        scribo_value = scribo_value.gsub("%{#{key}}", value) if value.is_a?(String)
      end
      scribo_value
    rescue
    end
  end
end
