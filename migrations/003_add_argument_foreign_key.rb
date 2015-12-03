Sequel.migration do
  up do
    alter_table(:arguments) do
      add_foreign_key :debate_id, :debates, :on_delete => :cascade
    end
  end

  down do
    drop_column :arguments, :debate_id
  end
end
