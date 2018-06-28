class CreateVarioSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :vario_settings, id: :uuid do |t|
      t.string :name
      t.string :description
      t.string :keys, default: [], array: true
      t.json :data

      t.timestamps
    end
  end
end
