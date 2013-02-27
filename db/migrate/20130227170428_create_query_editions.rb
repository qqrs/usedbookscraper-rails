class CreateQueryEditions < ActiveRecord::Migration
  def change
    create_table :query_editions do |t|
      t.integer :query_book_id
      t.integer :edition_id

      t.timestamps
    end

    add_index :query_editions, :query_book_id
    add_index :query_editions, :edition_id
    add_index :query_editions, [:query_book_id, :edition_id], unique: true
  end
end
