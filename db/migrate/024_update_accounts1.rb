class UpdateAccounts1 < ActiveRecord::Migration

    def self.up
        add_column :accounts, :user_id, :integer
		add_index :accounts, :user_id

		results=select_all("SELECT id, account_id from users")

		for row in results
			user_id=row['id']
			account_id=row['account_id']
			execute("UPDATE accounts SET user_id = #{user_id} WHERE id = #{account_id}")
		end

        remove_column :users, :account_id

    end

    def self.down

        add_column :users, :account_id, :integer

		results=select_all("SELECT id, user_id from accounts")

		for row in results
			user_id=row['user_id']
			account_id=row['id']
			execute("UPDATE users SET account_id = #{account_id} WHERE id = #{user_id}")
		end

        remove_column :accounts, :user_id
    end

end
