Sequel.migration do
  up do
    create_table(:arguments) do
      Integer :id, :primary_key=>true
      String :text, :null=>false
      Integer :type
      foreign_key :parent_id, :arguments
      foreign_key :user_id, :users
    end
  end

  down do
    drop_table(:arguments)
  end
end
