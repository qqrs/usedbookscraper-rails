class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :isbn
      t.string :title
      t.string :author

      t.timestamps
    end

    add_index :books, :isbn, unique: true
  end
end
