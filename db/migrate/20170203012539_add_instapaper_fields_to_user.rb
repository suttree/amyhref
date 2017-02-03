class AddInstapaperFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :instapaper_username, :string, :default => nil
    add_column :users, :instapaper_password, :string, :default => nil
  end
end
