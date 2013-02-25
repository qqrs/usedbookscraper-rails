class CreateQueryBooks < ActiveRecord::Migration
  def change
    create_table :query_books do |t|
      t.integer :query_id
      t.integer :book_id
      t.integer :desirabilty

      t.timestamps
    end

    add_index :query_books, :query_id
    add_index :query_books, :book_id
    add_index :query_books, [:query_id, :book_id], unique: true
  end
end
