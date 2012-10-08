class AddConfirmableToUsers < ActiveRecord::Migration
  def change
    add_column :users, :unconfirmed_email, :string
    add_index  :users, :confirmation_token, :unique => true
  end
end
