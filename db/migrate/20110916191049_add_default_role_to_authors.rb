class AddDefaultRoleToAuthors < ActiveRecord::Migration
  def change
    change_column_default :authors, :role, 'original'
  end
end
