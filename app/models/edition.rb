class Edition < ActiveRecord::Base
  attr_accessible :book_id, :isbn, :title, :author, :language, :published_date, :ed

  validates :isbn, presence: true, uniqueness: true

  belongs_to :book
  has_many :half_listings
end
