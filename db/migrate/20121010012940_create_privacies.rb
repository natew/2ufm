class CreatePrivacies < ActiveRecord::Migration
  def change
    create_table :privacies do |t|
      t.references :user
      t.boolean :mail_all, default: true
      t.boolean :mail_follows, default: true
      t.boolean :mail_shares, default: true
      t.boolean :mail_friend_joins, default: true

      t.timestamps
    end
  end
end
