# frozen_string_literal: true

# devise-jwt's JTIMatcher looks users up by jti on every authenticated API request and relies on it being unique.
# if_not_exists: some databases already have this index, added by hand.
class AddUniqueIndexToUsersJti < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :jti, unique: true, if_not_exists: true
  end
end
