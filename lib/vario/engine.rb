require 'importmap-rails'
require 'liquid'
require 'positioning'
require 'form_components'

module Vario
  class Engine < ::Rails::Engine
    config.autoload_paths << File.expand_path("../../lib", __dir__)

    isolate_namespace Vario

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    # Topics (Vario::Topic) in app/settings/ of the app and its engines, also
    # after a reload
    config.to_prepare do
      Vario::Topic.load!
    end

    initializer 'vario.assets' do |app|
      app.config.assets.paths << root.join('app/javascript') if app.config.respond_to?(:assets)
    end

    initializer 'vario.importmap', before: 'importmap' do |app|
      app.config.importmap.paths << root.join('config/importmap.rb')
      app.config.importmap.cache_sweepers << root.join('app/javascript')
    end
  end
end
