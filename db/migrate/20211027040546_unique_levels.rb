class UniqueLevels < ActiveRecord::Migration[6.1]
  def up
    Vario::Setting.all.each(&:uniq_levels!)
  end

  def down
  end
end
