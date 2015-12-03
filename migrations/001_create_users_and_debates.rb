Sequel.migration do
  up do
    create_table(:users) do
      Integer :id, :primary_key=>true
      String :username, :null=>false
    end

    create_table(:debates) do
        Integer :id, :primary_key=>true
        String :title, :null=>false
        foreign_key :user_id, :users
    end
  end

  down do
    drop_table(:debates, :users)
  end
end
