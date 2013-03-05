class CreateHalfSellers < ActiveRecord::Migration
  def change
    create_table :half_sellers do |t|
      t.string :name
      t.integer :feedback_count
      t.float :feedback_rating

      t.timestamps
    end

    add_index :half_sellers, :name
  end
end
