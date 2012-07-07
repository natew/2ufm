class InstallPgTrgrm < ActiveRecord::Migration
  def up
    sql = File.read(File.join(Rails.root,'vendor','pg_extensions','pg_trgm.sql'))
    execute sql
  end

  def down
    sql = File.read(File.join(Rails.root,'vendor','pg_extensions','uninstall_pg_trgm.sql'))
    execute sql
  end
end
