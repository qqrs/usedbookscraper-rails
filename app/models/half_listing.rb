class HalfListing < ActiveRecord::Base
  attr_accessible :comments, :condition, :edition_id, :half_item_id, :half_seller_id, :price

  belongs_to :edition
  belongs_to :half_seller
end
