class CreateHalfListings < ActiveRecord::Migration
  def change
    create_table :half_listings do |t|
      t.integer :edition_id
      t.float :price
      t.integer :half_item_id
      t.integer :half_seller_id
      t.string :comments
      t.string :condition

      t.timestamps
    end

    add_index :half_listings, :edition_id
    add_index :half_listings, :half_item_id
    add_index :half_listings, :half_seller_id
  end
end
