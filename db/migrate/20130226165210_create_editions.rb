class CreateEditions < ActiveRecord::Migration
  def change
    create_table :editions do |t|
      t.integer :book_id
      t.string :isbn
      t.string :title
      t.string :author
      t.string :language
      t.string :published_date
      t.string :ed

      t.timestamps
    end

    add_index :editions, :book_id
    add_index :editions, :isbn, unique: true
  end
end
