# frozen_string_literal: true

namespace :vario do
  desc "Convert 1.x settings (levels) to values and refinements; FORCE=1 also those already converted"
  task migrate: :environment do
    puts Vario::Migrator.new(force: ENV['FORCE'].present?).call(apply: true)
  end

  desc 'Write all settings and refinements to a JSON file (FILE, else vario_backup_<time>.json), to restore before running vario:migrate again'
  task backup: :environment do
    path = ENV['FILE'].presence || "vario_backup_#{Time.current.strftime('%Y%m%d%H%M%S')}.json"
    counts = Vario::Backup.write(path)
    puts "Backed up #{counts['settings']} settings and #{counts['refinements']} refinements to #{path}"
  end

  desc 'Replace all settings and refinements by those of a backup (FILE), exactly as they were then'
  task restore: :environment do
    path = ENV['FILE'].presence or abort 'FILE=<backup> is required'
    counts = Vario::Backup.restore(path)
    puts "Replaced #{counts[:before]['settings']} settings and #{counts[:before]['refinements']} refinements " \
         "by #{counts[:after]['settings']} and #{counts[:after]['refinements']} from #{path}"
  end

  namespace :migrate do
    desc 'What vario:migrate would do, per settable, without changing anything'
    task report: :environment do
      puts Vario::Migrator.new(force: ENV['FORCE'].present?).call(apply: false)
    end
  end
end
