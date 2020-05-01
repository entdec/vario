class IdsMustBeUuids < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :uuid, :uuid, default: "gen_random_uuid()", null: false
    change_table :accounts do |t|
      t.remove :id
      t.rename :uuid, :id
    end
    execute 'ALTER TABLE accounts ADD PRIMARY KEY(id);'

    add_column :products, :uuid, :uuid, default: "gen_random_uuid()", null: false
    change_table :products do |t|
      t.remove :id
      t.rename :uuid, :id
    end
    execute 'ALTER TABLE products ADD PRIMARY KEY(id);'
  end
end
