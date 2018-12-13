module Vario
  class ApplicationController < Vario.config.base_controller.constantize
    protect_from_forgery with: :exception

    def add_breadcrumbs(*args)
      method(:add_breadcrumbs).super_method&.call(*args)
    end

    def breadcrumb_settings_path(setting, options  = {})
      settings_path(options.merge(settable: setting.settable.to_sgid(for: 'Vario').to_s))
    end
  end
end
