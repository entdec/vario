module Vario
  class ApplicationController < Vario.config.base_controller.constantize
    protect_from_forgery with: :exception

    def add_breadcrumbs(*args)
      method(:add_breadcrumbs).super_method&.call(*args)
    end

    def breadcrumb_settings_path(setting)
      settings_path(settable: setting.settable.to_sgid(for: 'Scribo').to_s)
    end
  end
end
