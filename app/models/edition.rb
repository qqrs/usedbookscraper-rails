class Edition < ActiveRecord::Base
  attr_accessible :book_id, :isbn, :title, :author, :language, :published_date

  validates :isbn, presence: true, uniqueness: true

  belongs_to :book
end
