class HalfSeller < ActiveRecord::Base
  #has_no_table

  attr_accessible :feedback_count, :feedback_rating, :name
  #column :name, :string
  #column :feedback_count, :integer
  #column :feedback_rating, :float

  has_many :half_listings
  has_many :editions, through: :half_listings
  has_many :books, through: :editions
end
