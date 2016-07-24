class AddAltBayesRankingsToHrefs < ActiveRecord::Migration
  def change
    add_column :hrefs, :good_host2, :boolean, :default => false
    add_column :hrefs, :good_path2, :boolean, :default => false
    add_column :hrefs, :rating2, :float
  end
end
