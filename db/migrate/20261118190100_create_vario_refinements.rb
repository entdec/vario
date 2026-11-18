class CreateVarioRefinements < ActiveRecord::Migration[7.1]
  def change
    # A setting's more specific values: the first enabled one whose conditions
    # are met applies, by position
    create_table :vario_refinements, id: :uuid do |t|
      t.references :setting, type: :uuid, null: false, index: false, foreign_key: { to_table: :vario_settings, on_delete: :cascade }

      t.integer :position, null: false
      t.boolean :enabled, null: false, default: true
      t.text :note
      t.jsonb :conditions, null: false, default: { match: 'all', rules: [] }
      t.jsonb :value

      t.timestamps
    end

    add_index :vario_refinements, %i[setting_id position], unique: true
  end
end
