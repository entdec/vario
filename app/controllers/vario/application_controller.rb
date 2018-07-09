module Vario
  class ApplicationController < Vario.config.base_controller.constantize
    protect_from_forgery with: :exception

    def add_breadcrumbs(*args)
      method(:add_breadcrumbs).super_method&.call(*args)
    end
  end
end
