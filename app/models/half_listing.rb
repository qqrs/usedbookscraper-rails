class HalfListing < ActiveRecord::Base
  #has_no_table

  attr_accessible :comments, :condition, :edition_id, :half_item_id, :half_seller_id, :price
  #column :comments, :string
  #column :condition, :string
  #column :edition_id, :integer
  #column :half_item_id, :integer
  #column :half_seller_id, :integer
  #column :price,    :float

  belongs_to :edition
  belongs_to :half_seller
end
