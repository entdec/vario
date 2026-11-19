# frozen_string_literal: true

namespace :vario do
  desc "Convert 1.x settings (levels) to values and refinements; FORCE=1 also those already converted"
  task migrate: :environment do
    puts Vario::Migrator.new(force: ENV['FORCE'].present?).call(apply: true)
  end

  namespace :migrate do
    desc 'What vario:migrate would do, per settable, without changing anything'
    task report: :environment do
      puts Vario::Migrator.new(force: ENV['FORCE'].present?).call(apply: false)
    end
  end
end
