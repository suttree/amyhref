class AddUnreadToHrefs < ActiveRecord::Migration
  def change
    add_column :hrefs, :unread, :boolean, :default => true
    Href.update_all(unread: false)
  end
end
