class AddValueToVarioSettings < ActiveRecord::Migration[7.1]
  def change
    # The settable's own value for the setting, null when it has none
    add_column :vario_settings, :value, :jsonb

    add_index :vario_settings, %i[settable_type settable_id name], unique: true
  end
end
