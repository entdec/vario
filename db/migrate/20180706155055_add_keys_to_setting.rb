class AddKeysToSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :vario_settings, :keys, :string, array: true
  end
end
