class Book < ActiveRecord::Base
  attr_accessible :author, :isbn, :title

  validates :isbn, presence: true, uniqueness: true
  validates :author, presence: true
  validates :title, presence: true

  has_many :query_books
  has_many :books, through: :query_books
end
