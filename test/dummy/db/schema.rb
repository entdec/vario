# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_18_190100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vario_refinements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "setting_id", null: false
    t.integer "position", null: false
    t.boolean "enabled", default: true, null: false
    t.text "note"
    t.jsonb "conditions", default: {"match" => "all", "rules" => []}, null: false
    t.jsonb "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["setting_id", "position"], name: "index_vario_refinements_on_setting_id_and_position", unique: true
  end

  create_table "vario_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "settable_type"
    t.uuid "settable_id"
    t.string "name"
    t.json "levels"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "keys", array: true
    t.jsonb "value"
    t.index ["settable_type", "settable_id", "name"], name: "index_vario_settings_on_settable_type_and_settable_id_and_name", unique: true
    t.index ["settable_type", "settable_id"], name: "index_vario_settings_on_settable_type_and_settable_id"
  end

  add_foreign_key "vario_refinements", "vario_settings", column: "setting_id", on_delete: :cascade
end
