class CreateVarioSettings < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'plpgsql'
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'

    create_table :vario_settings, id: :uuid do |t|
      t.string :name
      t.string :category
      t.string :description
      t.string :keys, default: [], array: true
      t.json :data

      t.timestamps
    end
  end
end
