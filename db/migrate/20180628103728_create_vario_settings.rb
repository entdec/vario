class CreateVarioSettings < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'plpgsql'
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'

    create_table :vario_settings, id: :uuid do |t|
      t.references :settable, polymorphic: true, index: true, type: :uuid

      t.string :name
      t.string :category
      t.string :description
      t.string :keys, default: [], array: true

      t.json :levels

      t.timestamps
    end
  end
end
