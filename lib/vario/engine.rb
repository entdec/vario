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
  end
end
