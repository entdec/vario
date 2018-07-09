class RemoveFieldsFromSettings < ActiveRecord::Migration[5.2]
  def change
    remove_column :vario_settings, :category
    remove_column :vario_settings, :description
    remove_column :vario_settings, :keys
  end
end
