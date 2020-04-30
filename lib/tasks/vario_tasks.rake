# frozen_string_literal: true

namespace :vario do
  desc 'Release a new version'
  task :release do
    version_file = './lib/vario/version.rb'
    File.open(version_file, 'w') do |file|
      file.puts <<~EOVERSION
        # frozen_string_literal: true

        module Vario
          VERSION = '#{Vario::VERSION.split('.').map(&:to_i).tap { |parts| parts[2] += 1 }.join('.')}'
        end
      EOVERSION
    end
    module Vario
      remove_const :VERSION
    end
    load version_file
    puts "Updated version to #{Vario::VERSION}"

    `git commit lib/vario/version.rb -m "Version #{Vario::VERSION}"`
    `git push`
    `git tag #{Vario::VERSION}`
    `git push --tags`
  end
end
