class RemoveUniqueIndexFromBuilds < ActiveRecord::Migration
  def change
    # Remove unique index on git_sha, users should be able to rebuild docker images against same SHA
    remove_index :builds, :git_sha
    add_index :builds, :git_sha
  end
end
