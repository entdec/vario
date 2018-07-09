module Vario
  module I18nBackend
    def translate(locale, key, options = {})
      result = super
      Vario.config.translation_settable&.settings_prepopulate_cache
      scribo_value = Vario.config.translation_settable&.setting(key, default: result)
      result = scribo_value if scribo_value
      result
    end
  end
end
