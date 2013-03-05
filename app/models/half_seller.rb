class HalfSeller < ActiveRecord::Base
  attr_accessible :feedback_count, :feedback_rating, :name

  has_many :half_listings
  has_many :editions, through :half_listings
  has_many :books, through :editions
end
